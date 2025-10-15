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

  describe 'provisioned throughput configuration' do
    let(:vertex_ai_config) do
      {
        credentials: {
          service: 'vertex-ai-api',
          project_id: 'test-project',
          region: 'us-central1',
          api_key: 'test-api-key'
        },
        options: {
          model: 'gemini-1.5-pro'
        }
      }
    end

    let(:generative_language_config) do
      {
        credentials: {
          service: 'generative-language-api',
          api_key: 'test-api-key'
        },
        options: {
          model: 'gemini-1.5-pro'
        }
      }
    end

    context 'with vertex-ai-api service' do
      it 'accepts valid provisioned throughput configurations' do
        %w[dedicated shared spillover].each do |config|
          expect do
            described_class.new(vertex_ai_config.merge(
              options: vertex_ai_config[:options].merge(provisioned_throughput: config)
            ))
          end.not_to raise_error
        end
      end

      it 'rejects invalid provisioned throughput configurations' do
        expect do
          described_class.new(vertex_ai_config.merge(
            options: vertex_ai_config[:options].merge(provisioned_throughput: 'invalid')
          ))
        end.to raise_error(
          Gemini::Errors::InvalidProvisionedThroughputError,
          "Invalid config 'invalid'. Must be one of: dedicated, shared, spillover"
        )
      end

      it 'rejects non-string provisioned throughput configurations' do
        expect do
          described_class.new(vertex_ai_config.merge(
            options: vertex_ai_config[:options].merge(provisioned_throughput: { config: 'dedicated' })
          ))
        end.to raise_error(
          Gemini::Errors::InvalidProvisionedThroughputError,
          'provisioned_throughput must be a string with one of: dedicated, shared, spillover'
        )
      end

      it 'allows nil provisioned throughput configuration' do
        expect do
          described_class.new(vertex_ai_config)
        end.not_to raise_error
      end
    end

    context 'with generative-language-api service' do
      it 'ignores provisioned throughput configuration' do
        expect do
          described_class.new(generative_language_config.merge(
            options: generative_language_config[:options].merge(provisioned_throughput: 'dedicated')
          ))
        end.not_to raise_error
      end

      it 'ignores invalid provisioned throughput configuration' do
        expect do
          described_class.new(generative_language_config.merge(
            options: generative_language_config[:options].merge(provisioned_throughput: 'invalid')
          ))
        end.not_to raise_error
      end

      it 'ignores non-string provisioned throughput configuration' do
        expect do
          described_class.new(generative_language_config.merge(
            options: generative_language_config[:options].merge(provisioned_throughput: { config: 'dedicated' })
          ))
        end.not_to raise_error
      end
    end
  end
end
