# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/gemini-ai'

# # References:
# # - https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning
# # - https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models

CACHE_FILE_PATH = 'available-models.tmp'

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
  'text-embedding-004',
  'embedding-001',
  'text-multilingual-embedding-002',
  'textembedding-gecko-multilingual@001',
  'textembedding-gecko-multilingual@latest',
  'textembedding-gecko@001',
  'textembedding-gecko@002',
  'textembedding-gecko@003',
  'textembedding-gecko@latest'
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

      output = if model =~ /embed/
                 if service == 'vertex-ai-api'
                   client.predict(
                     { instances: [{ content: 'What is life?' }] }
                   )
                 else
                   client.embed_content(
                     { content: { parts: [{ text: 'What is life?' }] } }
                   )
                 end
               else
                 client.stream_generate_content(
                   { contents: { role: 'user', parts: { text: 'hi!' } } }
                 )
               end

      results[key] = {
        service:, model:,
        result: 'success', output:
      }

      print '.'
    rescue StandardError => e
      results[key] = {
        service:, model:,
        result: 'error', output: e.message
      }

      print '*'
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
  table[result[:model]][result[:service]] = result[:result] == 'success' ? '✅' : '🔒'
end

table.values.sort_by { |row| models.index(row[:model]) }.each do |row|
  puts "| #{row[:model].ljust(40)} | #{row['vertex-ai-api'].rjust(4).ljust(8)} | #{row['generative-language-api'].rjust(10).ljust(18)} |"
end
