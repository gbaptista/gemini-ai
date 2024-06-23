# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/gemini-ai'

# # References:
# # - https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning
# # - https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models

CACHE_FILE_PATH = 'available-models-json.tmp'

models = [
  'gemini-pro-vision',
  'gemini-pro',
  'gemini-1.5-pro-preview-0514',
  'gemini-1.5-pro-preview-0409',
  'gemini-1.5-pro',
  'gemini-1.5-flash-preview-0514',
  'gemini-1.5-flash',
  'gemini-1.0-pro-vision-latest',
  'gemini-1.0-pro-vision-001',
  'gemini-1.0-pro-vision',
  'gemini-1.0-pro-latest',
  'gemini-1.0-pro-002',
  'gemini-1.0-pro-001',
  'gemini-1.0-pro',
  'gemini-ultra',
  'gemini-1.0-ultra',
  'gemini-1.0-ultra-001'
]

def client_for(service, model)
  credentials = if service == 'vertex-ai-api'
                  { service: 'vertex-ai-api', region: 'us-east4' }
                else
                  { service: 'generative-language-api',
                    api_key: ENV.fetch('GOOGLE_API_KEY', nil) }
                end

  Gemini.new(credentials:, options: { model:, server_sent_events: true })
end

if File.exist?(CACHE_FILE_PATH)
  results = Marshal.load(File.read(CACHE_FILE_PATH))
else
  results = {}

  models.each do |model|
    %w[vertex-ai-api generative-language-api].each do |service|
      key = "#{service}/#{model}"

      client = client_for(service, model)

      begin
        sleep 1
        client.stream_generate_content(
          { contents: { role: 'user', parts: { text: 'hi!' } } }
        )
      rescue Faraday::BadRequestError, Faraday::ResourceNotFound => e
        results[key] = {
          service:, model:,
          result: 'access-error', output: e.message
        }

        print '-'
        next
      end

      begin
        sleep 1
        client.stream_generate_content(
          {
            contents: {
              role: 'user',
              parts: {
                text: 'List 3 random colors.'
              }
            },
            generation_config: {
              response_mime_type: 'application/json'
            }
          }
        )
      rescue Faraday::BadRequestError, Faraday::ResourceNotFound => e
        results[key] = {
          service:, model:,
          result: 'json-error', output: e.message
        }

        print '*'
        next
      end

      begin
        sleep 1
        output = client.stream_generate_content(
          {
            contents: {
              role: 'user',
              parts: {
                text: 'List 3 random colors.'
              }
            },
            generation_config: {
              response_mime_type: 'application/json',
              response_schema: {
                type: 'object',
                properties: {
                  colors: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        name: {
                          type: 'string'
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        )

        results[key] = {
          service:, model:,
          result: 'success', output:
        }

        print '.'
      rescue Faraday::BadRequestError, Faraday::ResourceNotFound => e
        results[key] = {
          service:, model:,
          result: 'schema-error', output: e.message
        }

        print '/'
      end
    end
  end

  puts ''

  File.write(CACHE_FILE_PATH, Marshal.dump(results))
end

puts '| Model                                    | Vertex AI | Generative Language |'
puts '|------------------------------------------|:---------:|:-------------------:|'

table = {}

results.each_value do |result|
  table[result[:model]] = { model: result[:model] } unless table.key?(result[:model])
  table[result[:model]][result[:service]] = case result[:result]
                                            when 'success'
                                              '✅'
                                            when 'access-error'
                                              '🔒'
                                            when 'schema-error'
                                              '🟡'
                                            when 'json-error'
                                              '❌'
                                            else
                                              '?'
                                            end
end

table.values.sort_by { |row| models.index(row[:model]) }.each do |row|
  puts "| #{row[:model].ljust(40)} | #{row['vertex-ai-api'].rjust(4).ljust(8)} | #{row['generative-language-api'].rjust(10).ljust(18)} |"
end
