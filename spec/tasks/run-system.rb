# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/gemini-ai'

client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

result = client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'Hi! Who are you?' } },
    system_instruction: { role: 'user', parts: [{ text: 'You are a cat.' }, { text: 'Your name is Neko.' }] } }
) do |event, _parsed, _raw|
  print event['candidates'][0]['content']['parts'][0]['text']
end

puts "\n#{'-' * 20}"

puts result.map { |event| event['candidates'][0]['content']['parts'][0]['text'] }.join
