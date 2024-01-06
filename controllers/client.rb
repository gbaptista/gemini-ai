# frozen_string_literal: true

require 'event_stream_parser'
require 'faraday'
require 'json'
require 'googleauth'

require_relative '../ports/dsl/gemini-ai/errors'

module Gemini
  module Controllers
    class Client
      ALLOWED_REQUEST_OPTIONS = %i[timeout open_timeout read_timeout write_timeout].freeze

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
          @project_id = config[:credentials][:project_id] || @authorizer.project_id || @authorizer.quota_project_id

          raise MissingProjectIdError, 'Could not determine project_id, which is required.' if @project_id.nil?
        end

        @service = config[:credentials][:service]

        @address = case @service
                   when 'vertex-ai-api'
                     "https://#{config[:credentials][:region]}-aiplatform.googleapis.com/v1/projects/#{@project_id}/locations/#{config[:credentials][:region]}/publishers/google/models/#{config[:options][:model]}"
                   when 'generative-language-api'
                     "https://generativelanguage.googleapis.com/v1/models/#{config[:options][:model]}"
                   else
                     raise UnsupportedServiceError, "Unsupported service: #{@service}"
                   end

        @server_sent_events = config[:options][:server_sent_events]

        @request_options = config.dig(:options, :connection, :request)

        @request_options = if @request_options.is_a?(Hash)
                             @request_options.select do |key, _|
                               ALLOWED_REQUEST_OPTIONS.include?(key)
                             end
                           else
                             {}
                           end
      end

      def stream_generate_content(payload, server_sent_events: nil, &callback)
        request('streamGenerateContent', payload, server_sent_events:, &callback)
      end

      def generate_content(payload, server_sent_events: nil, &callback)
        result = request('generateContent', payload, server_sent_events:, &callback)

        return result.first if result.is_a?(Array) && result.size == 1

        result
      end

      def request(path, payload, server_sent_events: nil, &callback)
        server_sent_events_enabled = server_sent_events.nil? ? @server_sent_events : server_sent_events
        url = "#{@address}:#{path}"
        params = []

        params << 'alt=sse' if server_sent_events_enabled
        params << "key=#{@api_key}" if @authentication == :api_key

        url += "?#{params.join('&')}" if params.size.positive?

        if !callback.nil? && !server_sent_events_enabled
          raise BlockWithoutServerSentEventsError,
                'You are trying to use a block without Server Sent Events (SSE) enabled.'
        end

        results = []

        response = Faraday.new(request: @request_options) do |faraday|
          faraday.response :raise_error
        end.post do |request|
          request.url url
          request.headers['Content-Type'] = 'application/json'
          if @authentication == :service_account || @authentication == :default_credentials
            request.headers['Authorization'] = "Bearer #{@authorizer.fetch_access_token!['access_token']}"
          end

          request.body = payload.to_json

          if server_sent_events_enabled
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

                if parsed_data['candidates']
                  parsed_data['candidates'].find do |candidate|
                    !candidate['finishReason'].nil? && candidate['finishReason'] != ''
                  end
                end
              end
            end
          end
        end

        return safe_parse_json(response.body) unless server_sent_events_enabled

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
