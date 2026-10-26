# frozen_string_literal: true

require 'socket'

require_relative '../../ports/dsl/gemini-ai'
require_relative '../../components/errors'

# Runs against a real local HTTP server, not Typhoeus.stub: stubbed responses keep their body, so they never
# reproduce the streamed (empty) body Typhoeus leaves on a real non-200 SSE reply.
RSpec.describe Gemini do
  let(:server) { TCPServer.new('127.0.0.1', 0) }
  let(:client) do
    described_class.new(
      credentials: { service: 'generative-language-api', api_key: 'key' },
      options: { model: 'gemini-pro', server_sent_events: true }
    ).tap do |client|
      client.instance_variable_set(:@base_address, "http://127.0.0.1:#{server.addr[1]}/v1")
    end
  end
  let(:payload) { { contents: { role: 'user', parts: { text: 'hi' } } } }

  after { server.close }

  def serve(status, content_type, body)
    Thread.new do
      socket = server.accept
      headers = []
      headers << socket.gets until headers.last == "\r\n"
      socket.read(headers.find { |line| line =~ /\Acontent-length:/i }.split(':').last.to_i)
      socket.write("HTTP/1.1 #{status}\r\nContent-Type: #{content_type}\r\n" \
                   "Content-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
      socket.close
    end
  end

  context 'when Gemini rejects a streaming request' do
    let(:error_body) do
      { error: { code: 400, message: 'Invalid value at function_declarations[0]', status: 'INVALID_ARGUMENT' } }.to_json
    end

    before { serve('400 Bad Request', 'application/json', error_body) }

    it 'raises the client error with the error body' do
      expect { client.stream_generate_content(payload) }
        .to raise_error(an_instance_of(Faraday::BadRequestError)
          .and(having_attributes(response: hash_including(status: 400, body: error_body))))
    end
  end

  context 'when the adapter passes env to on_data' do
    let(:error_body) { '{"error":{"code":400,"message":"Invalid argument"}}' }

    before do
      client.instance_variable_set(:@faraday_adapter, :net_http)
      serve('400 Bad Request', 'application/json', error_body)
    end

    it 'keeps the body the status check raised with' do
      expect { client.stream_generate_content(payload) }
        .to raise_error(an_instance_of(Faraday::BadRequestError)
          .and(having_attributes(response: hash_including(status: 400, body: error_body))))
    end
  end

  context 'when Gemini fails a streaming request on its side' do
    before { serve('500 Internal Server Error', 'application/json', '{"error":{"code":500,"message":"Internal"}}') }

    it 'raises a RequestError wrapping the server error and its body' do
      expect { client.stream_generate_content(payload) }
        .to raise_error(an_instance_of(Gemini::Errors::RequestError)
          .and(having_attributes(request: having_attributes(response: hash_including(body: /Internal/)))))
    end
  end

  context 'when the stream succeeds' do
    let(:events) do
      [{ candidates: [{ content: { parts: [{ text: 'Hello' }] } }] },
       { candidates: [{ content: { parts: [{ text: '!' }] }, finishReason: 'STOP' }] }]
    end

    before { serve('200 OK', 'text/event-stream', events.map { |event| "data: #{event.to_json}\n\n" }.join) }

    it 'returns the parsed events' do
      texts = client.stream_generate_content(payload).map { |event| event.dig('candidates', 0, 'content', 'parts', 0) }

      expect(texts).to eq([{ 'text' => 'Hello' }, { 'text' => '!' }])
    end
  end
end
