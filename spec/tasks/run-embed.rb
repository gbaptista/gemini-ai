# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/gemini-ai'

client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV.fetch('GOOGLE_API_KEY', nil)
  },
  options: { model: 'text-embedding-004', server_sent_events: true }
)

result = client.embed_content(
  { content: { parts: [{ text: 'What is life?' }] } }
)

# File.write('temp.rb', PP.pp(result, String.new))

puts result.keys

puts '-' * 20

result = client.batch_embed_content(
  {
    requests: [
      {
        model: 'models/text-embedding-004',
        content: { parts: [ {text: 'What is life?' } ] },
        output_dimensionality: 64,
        task_type: "CLUSTERING"
      },
      {
        model: 'models/text-embedding-004',
        content: { parts: [ {text: 'What is the meaning of life?' } ] },
        output_dimensionality: 64,
        task_type: "CLUSTERING"
      }
    ]
  }
)

puts result.keys

puts '-' * 20

client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    region: 'us-east4'
  },
  options: { model: 'text-embedding-004', server_sent_events: true }
)

result = client.predict(
  { instances: [{ content: 'What is life?' }],
    parameters: { autoTruncate: true } }
)

puts result.keys

# File.write('temp.rb', PP.pp(result, String.new))
