# frozen_string_literal: true

require 'event_stream_parser'
require 'faraday'
require 'json'
require 'googleauth'

require_relative '../components/errors'

module Gemini
  module Controllers
    class Client
      def initialize(config)
        if config[:credentials][:api_key]
          @authentication = :api_key
          @api_key = config[:credentials][:api_key]
        elsif config[:credentials][:file_path]
          @authentication = :service_account
          @authorizer = ::Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io: File.open(config[:credentials][:file_path]),
            scope: 'https://www.googleapis.com/auth/cloud-platform'
          )
        else
          @authentication = :default_credentials
          @authorizer = ::Google::Auth.get_application_default
        end

        if @authentication == :service_account || @authentication == :default_credentials
          @project_id = if config[:credentials][:project_id].nil?
                          @authorizer.project_id || @authorizer.quota_project_id
                        else
                          config[:credentials][:project_id]
                        end

          raise MissingProjectIdError, 'Could not determine project_id, which is required.' if @project_id.nil?
        end

        @address = case config[:credentials][:service]
                   when 'vertex-ai-api'
                     "https://#{config[:credentials][:region]}-aiplatform.googleapis.com/v1/projects/#{@project_id}/locations/#{config[:credentials][:region]}/publishers/google/models/#{config[:options][:model]}"
                   when 'generative-language-api'
                     "https://generativelanguage.googleapis.com/v1/models/#{config[:options][:model]}"
                   else
                     raise UnsupportedServiceError, "Unsupported service: #{config[:credentials][:service]}"
                   end

        @stream = config[:options][:stream]
      end

      def stream_generate_content(payload, stream: nil, &callback)
        request('streamGenerateContent', payload, stream:, &callback)
      end

      def request(path, payload, stream: nil, &callback)
        stream_enabled = stream.nil? ? @stream : stream
        url = "#{@address}:#{path}"
        params = []

        params << 'alt=sse' if stream_enabled
        params << "key=#{@api_key}" if @authentication == :api_key

        url += "?#{params.join('&')}" if params.size.positive?

        if !callback.nil? && !stream_enabled
          raise BlockWithoutStreamError, 'You are trying to use a block without stream enabled.'
        end

        results = []

        response = Faraday.new do |faraday|
          faraday.response :raise_error
        end.post do |request|
          request.url url
          request.headers['Content-Type'] = 'application/json'
          if @authentication == :service_account || @authentication == :default_credentials
            request.headers['Authorization'] = "Bearer #{@authorizer.fetch_access_token!['access_token']}"
          end

          request.body = payload.to_json

          if stream_enabled
            parser = EventStreamParser::Parser.new

            request.options.on_data = proc do |chunk, bytes, env|
              if env && env.status != 200
                raise_error = Faraday::Response::RaiseError.new
                raise_error.on_complete(env.merge(body: chunk))
              end

              parser.feed(chunk) do |type, data, id, reconnection_time|
                parsed_data = safe_parse_json(data)
                result = {
                  event: safe_parse_json(data),
                  parsed: { type:, data:, id:, reconnection_time: },
                  raw: { chunk:, bytes:, env: }
                }

                callback.call(result[:event], result[:parsed], result[:raw]) unless callback.nil?

                results << result

                parsed_data['candidates'].find do |candidate|
                  !candidate['finishReason'].nil? && candidate['finishReason'] != ''
                end
              end
            end
          end
        end

        return safe_parse_json(response.body) unless stream_enabled

        results.map { |result| result[:event] }
      rescue Faraday::ServerError => e
        raise RequestError.new(e.message, request: e, payload:)
      end

      def safe_parse_json(raw)
        raw.start_with?('{', '[') ? JSON.parse(raw) : raw
      rescue JSON::ParserError
        raw
      end
    end
  end
end
