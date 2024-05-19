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
    safetySettings: [{ category: 'HARM_CATEGORY_UNSPECIFIED', threshold: 'BLOCK_ONLY_HIGH' },
                     { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_ONLY_HIGH' },
                     { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_ONLY_HIGH' },
                     { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' },
                     { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_ONLY_HIGH' }] }
) do |event, _parsed, _raw|
  print event['candidates'][0]['content']['parts'][0]['text']
end

puts "\n#{'-' * 20}"

puts result.map { |event| event['candidates'][0]['content']['parts'][0]['text'] }.join
