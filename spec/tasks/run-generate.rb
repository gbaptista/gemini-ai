# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/gemini-ai'

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
  print event.dig('candidates', 0, 'content', 'parts', 0, 'text')
end

puts "\n#{'-' * 20}"

puts result.map { |event| event.dig('candidates', 0, 'content', 'parts', 0, 'text') }.join

puts '-' * 20

client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

result = client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }
) do |event, _parsed, _raw|
  print event.dig('candidates', 0, 'content', 'parts', 0, 'text')
end

puts "\n#{'-' * 20}"

puts result.map { |event| event.dig('candidates', 0, 'content', 'parts', 0, 'text') }.join
