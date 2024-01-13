# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/gemini-ai'

begin
  client = Gemini.new(
    credentials: {
      service: 'unknown-service'
    },
    options: { model: 'gemini-pro', server_sent_events: true }
  )

  client.stream_generate_content(
    { contents: { role: 'user', parts: { text: 'hi!' } } }
  )
rescue StandardError => e
  raise "Unexpected error: #{e.class}" unless e.instance_of?(Gemini::Errors::UnsupportedServiceError)
end

client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV.fetch('GOOGLE_API_KEY', nil)
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

result = client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }
) do |event, _parsed, _raw|
  print event['candidates'][0]['content']['parts'][0]['text']
end

puts "\n#{'-' * 20}"

puts result.map { |event| event['candidates'][0]['content']['parts'][0]['text'] }.join
