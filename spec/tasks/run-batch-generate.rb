# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/gemini-ai'

client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV.fetch('GOOGLE_API_KEY', nil)
  },
  options: { model: 'gemini-3.5-flash' }
)

result = client.batch_generate_content(
  {
    batch: {
      display_name: 'my-batch-requests',
      input_config: {
        requests: {
          requests: [
            {
              request: {
                contents: {
                  role: 'user',
                  parts: {
                    text: 'hi!'
                  }
                }
              },
              metadata: {
                key: 'request-1'
              }
            },
            {
              request: {
                contents: {
                  role: 'user',
                  parts: {
                    text: 'tell me a joke'
                  }
                }
              },
              metadata: {
                key: 'request-2'
              }
            }
          ]
        }
      }
    }
  }
)

puts '-' * 20

name = result['name']

loop do
  batch = client.batch(name)

  state = batch.dig('metadata', 'state')

  puts "Batch state: #{state}"

  if state == 'BATCH_STATE_SUCCEEDED'
    client.batch_responses(batch).each do |response|
      key = response.dig('metadata', 'key')

      text = response.dig(
        'response',
        'candidates',
        0,
        'content',
        'parts',
        0,
        'text'
      )

      puts "[#{key}] #{text}"
    end

    break
  else
    puts 'Waiting until batch succeed'
  end

  sleep 2
end

puts '-' * 20
