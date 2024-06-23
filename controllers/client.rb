# frozen_string_literal: true

require 'event_stream_parser'
require 'faraday'
require 'faraday/typhoeus'
require 'json'
require 'googleauth'

require_relative '../components/errors'

module Gemini
  module Controllers
    class Client
      ALLOWED_REQUEST_OPTIONS = %i[timeout open_timeout read_timeout write_timeout].freeze

      DEFAULT_FARADAY_ADAPTER = :typhoeus

      DEFAULT_SERVICE_VERSION = 'v1'

      def initialize(config)
        @service = config[:credentials][:service]

        unless %w[vertex-ai-api generative-language-api].include?(@service)
          raise Errors::UnsupportedServiceError, "Unsupported service: #{@service}"
        end

        if config[:credentials][:api_key]
          @authentication = :api_key
          @api_key = config[:credentials][:api_key]
        elsif config[:credentials].key?(:file_path) && config[:credentials].key?(:file_contents)
          raise Errors::ConflictingCredentialsError,
                "You must choose 'file_path' or 'file_contents,' not both."
        elsif config[:credentials][:file_path] || config[:credentials][:file_contents]
          @authentication = :service_account
          json_key_io = if config[:credentials][:file_path]
                          File.open(config[:credentials][:file_path])
                        else
                          StringIO.new(config[:credentials][:file_contents])
                        end

          @authorizer = ::Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io:,
            scope: 'https://www.googleapis.com/auth/cloud-platform'
          )
        else
          @authentication = :default_credentials
          @authorizer = ::Google::Auth.get_application_default
        end

        if @authentication == :service_account || @authentication == :default_credentials
          @project_id = config[:credentials][:project_id] || @authorizer.project_id || @authorizer.quota_project_id

          raise Errors::MissingProjectIdError, 'Could not determine project_id, which is required.' if @project_id.nil?
        end

        @service_version = config.dig(:credentials, :version) || DEFAULT_SERVICE_VERSION

        @base_address = case @service
                        when 'vertex-ai-api'
                          "https://#{config[:credentials][:region]}-aiplatform.googleapis.com/#{@service_version}/projects/#{@project_id}/locations/#{config[:credentials][:region]}"
                        when 'generative-language-api'
                          "https://generativelanguage.googleapis.com/#{@service_version}"
                        end

        @model_address = case @service
                         when 'vertex-ai-api'
                           "publishers/google/models/#{config[:options][:model]}"
                         when 'generative-language-api'
                           "models/#{config[:options][:model]}"
                         end

        @server_sent_events = config.dig(:options, :server_sent_events)

        @request_options = config.dig(:options, :connection, :request)

        @faraday_adapter = config.dig(:options, :connection, :adapter) || DEFAULT_FARADAY_ADAPTER

        @request_options = if @request_options.is_a?(Hash)
                             @request_options.select do |key, _|
                               ALLOWED_REQUEST_OPTIONS.include?(key)
                             end
                           else
                             {}
                           end
      end

      def predict(payload, server_sent_events: nil, &callback)
        result = request(
          "#{@model_address}:predict", payload,
          server_sent_events:, &callback
        )

        return result.first if result.is_a?(Array) && result.size == 1

        result
      end

      def embed_content(payload, server_sent_events: nil, &callback)
        result = request(
          "#{@model_address}:embedContent", payload,
          server_sent_events:, &callback
        )

        return result.first if result.is_a?(Array) && result.size == 1

        result
      end

      def stream_generate_content(payload, server_sent_events: nil, &callback)
        request("#{@model_address}:streamGenerateContent", payload, server_sent_events:, &callback)
      end

      def models(_server_sent_events: nil, &callback)
        result = request(
          'models',
          nil, server_sent_events: false, request_method: 'GET', &callback
        )

        return result.first if result.is_a?(Array) && result.size == 1

        result
      end

      def generate_content(payload, server_sent_events: nil, &callback)
        result = request(
          "#{@model_address}:generateContent", payload,
          server_sent_events:, &callback
        )

        return result.first if result.is_a?(Array) && result.size == 1

        result
      end

      def request(path, payload, server_sent_events: nil, request_method: 'POST', &callback)
        server_sent_events_enabled = server_sent_events.nil? ? @server_sent_events : server_sent_events

        url = "#{@base_address}/#{path}"

        params = []

        params << 'alt=sse' if server_sent_events_enabled
        params << "key=#{@api_key}" if @authentication == :api_key

        url += "?#{params.join('&')}" if params.size.positive?

        if !callback.nil? && !server_sent_events_enabled
          raise Errors::BlockWithoutServerSentEventsError,
                'You are trying to use a block without Server Sent Events (SSE) enabled.'
        end

        results = []

        method_to_call = request_method.to_s.strip.downcase.to_sym

        response = Faraday.new(request: @request_options) do |faraday|
          faraday.adapter @faraday_adapter
          faraday.response :raise_error
        end.send(method_to_call) do |request|
          request.url url
          request.headers['Content-Type'] = 'application/json'
          if @authentication == :service_account || @authentication == :default_credentials
            request.headers['Authorization'] = "Bearer #{@authorizer.fetch_access_token!['access_token']}"
          end

          request.body = payload.to_json unless payload.nil?

          if server_sent_events_enabled
            partial_json = ''

            parser = EventStreamParser::Parser.new

            request.options.on_data = proc do |chunk, bytes, env|
              if env && env.status != 200
                raise_error = Faraday::Response::RaiseError.new
                raise_error.on_complete(env.merge(body: chunk))
              end

              parser.feed(chunk) do |type, data, id, reconnection_time|
                partial_json += data

                parsed_json = safe_parse_json(partial_json)

                if parsed_json
                  result = {
                    event: parsed_json,
                    parsed: { type:, data:, id:, reconnection_time: },
                    raw: { chunk:, bytes:, env: }
                  }

                  callback.call(result[:event], result[:parsed], result[:raw]) unless callback.nil?

                  results << result

                  partial_json = ''

                  if parsed_json['candidates']
                    parsed_json['candidates'].find do |candidate|
                      !candidate['finishReason'].nil? && candidate['finishReason'] != ''
                    end
                  end
                end
              end
            end
          end
        end

        return safe_parse_json(response.body) unless server_sent_events_enabled

        results.map { |result| result[:event] }
      rescue Faraday::ServerError => e
        raise Errors::RequestError.new(e.message, request: e, payload:)
      end

      def safe_parse_json(raw)
        raw.to_s.lstrip.start_with?('{', '[') ? JSON.parse(raw) : nil
      rescue JSON::ParserError
        nil
      end
    end
  end
end
