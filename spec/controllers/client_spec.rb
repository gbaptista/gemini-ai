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

  describe 'Vertex AI base address' do
    {
      'global' => 'https://aiplatform.googleapis.com/v1/projects//locations/global',
      'eu' => 'https://aiplatform.eu.rep.googleapis.com/v1/projects//locations/eu',
      'us' => 'https://aiplatform.us.rep.googleapis.com/v1/projects//locations/us',
      'us-east4' => 'https://us-east4-aiplatform.googleapis.com/v1/projects//locations/us-east4',
      'europe-west9' => 'https://europe-west9-aiplatform.googleapis.com/v1/projects//locations/europe-west9'
    }.each do |region, base_address|
      it "builds the endpoint for '#{region}'" do
        client = described_class.new(
          credentials: { service: 'vertex-ai-api', api_key: 'key', region: },
          options: { model: 'gemini-2.5-flash' }
        )

        expect(client.instance_variable_get(:@base_address)).to eq(base_address)
      end
    end
  end
end
