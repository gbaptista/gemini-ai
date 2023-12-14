# frozen_string_literal: true

require 'event_stream_parser'
require 'faraday'
require 'json'
require 'googleauth'

module Gemini
  module Controllers
    class Client
      def initialize(config)
        @authorizer = ::Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(config[:credentials][:file_path]),
          scope: 'https://www.googleapis.com/auth/cloud-platform'
        )

        @address = "https://#{config[:credentials][:region]}-aiplatform.googleapis.com/v1/projects/#{config[:credentials][:project_id]}/locations/#{config[:credentials][:region]}/publishers/google/models/#{config[:settings][:model]}"

        @stream = config[:settings][:stream]
      end

      def stream_generate_content(payload, stream: nil, &callback)
        request('streamGenerateContent', payload, stream:, &callback)
      end

      def request(path, payload, stream: nil, &callback)
        stream_enabled = stream.nil? ? @stream : stream
        url = "#{@address}:#{path}"
        url += '?alt=sse' if stream_enabled

        if !callback.nil? && !stream_enabled
          raise StandardError, 'You are trying to use a block without stream enabled."'
        end

        results = []

        response = Faraday.new.post do |request|
          request.url url
          request.headers['Content-Type'] = 'application/json'
          request.headers['Authorization'] = "Bearer #{@authorizer.fetch_access_token!['access_token']}"
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
      end

      def safe_parse_json(raw)
        raw.start_with?('{', '[') ? JSON.parse(raw) : raw
      rescue JSON::ParserError
        raw
      end
    end
  end
end
