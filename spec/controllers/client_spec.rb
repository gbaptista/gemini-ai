# frozen_string_literal: true

require_relative '../../ports/dsl/gemini-ai'
require_relative '../../components/errors'

RSpec.describe Gemini do
  it 'avoids unsupported services' do
    expect do
      described_class.new(
        credentials: {
          service: 'unknown-service'
        }
      )
    end.to raise_error(
      Gemini::Errors::UnsupportedServiceError,
      "Unsupported service: 'unknown-service'."
    )
  end

  it 'avoids conflicts with credential keys' do
    expect do
      described_class.new(
        credentials: {
          service: 'vertex-ai-api',
          api_key: 'key',
          file_path: 'path',
          file_contents: 'contents'
        }
      )
    end.to raise_error(
      Gemini::Errors::ConflictingCredentialsError,
      "You must choose either 'api_key', 'file_contents', or 'file_path'."
    )

    expect do
      described_class.new(
        credentials: {
          service: 'vertex-ai-api',
          file_path: 'path',
          file_contents: 'contents'
        }
      )
    end.to raise_error(
      Gemini::Errors::ConflictingCredentialsError,
      "You must choose either 'file_contents', or 'file_path'."
    )
  end

  describe 'custom base address' do
    it 'uses the custom base address when provided' do
      custom_base_address = 'https://custom-gemini-api.example.com/v1'
      client = described_class.new(
        credentials: {
          service: 'vertex-ai-api',
          region: 'us-east4',
          base_address: custom_base_address,
          api_key: 'key'
        },
        options: { model: 'gemini-pro' }
      )

      expect(client.base_address).to eq(custom_base_address)
    end

    it 'uses the default base address when not provided' do
      client = described_class.new(
        credentials: {
          service: 'vertex-ai-api',
          region: 'us-east4',
          api_key: 'key'
        },
        options: { model: 'gemini-pro' }
      )

      expect(client.base_address).to include('aiplatform.googleapis.com')
    end
  end

  describe 'custom headers' do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:faraday_test_adapter) { :test }

    it 'sends custom headers with the request' do
      custom_headers = { 'X-Custom-Header' => 'CustomValue' }

      stubs.post(/.*/) do |env|
        expect(env.request_headers).to include(custom_headers)
        [200, {}, '{}']
      end

      client = described_class.new(
        credentials: {
          service: 'vertex-ai-api',
          region: 'us-east4',
          api_key: 'key'
        },
        options: {
          model: 'gemini-pro',
          headers: custom_headers,
          connection: { adapter: [:test, stubs] }
        }
      )

      client.predict({ content: 'Test' })
      stubs.verify_stubbed_calls
    end
  end
end
