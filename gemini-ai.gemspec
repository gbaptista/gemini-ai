# frozen_string_literal: true

require_relative 'static/gem'

Gem::Specification.new do |spec|
  spec.name    = Gemini::GEM[:name]
  spec.version = Gemini::GEM[:version]
  spec.authors = [Gemini::GEM[:author]]

  spec.summary = Gemini::GEM[:summary]
  spec.description = Gemini::GEM[:description]

  spec.homepage = Gemini::GEM[:github]

  spec.license = Gemini::GEM[:license]

  spec.required_ruby_version = Gem::Requirement.new(">= #{Gemini::GEM[:ruby]}")

  spec.metadata['allowed_push_host'] = Gemini::GEM[:gem_server]

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = Gemini::GEM[:github]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.require_paths = ['ports/dsl']

  spec.add_dependency 'event_stream_parser', '~> 1.0'
  spec.add_dependency 'faraday', '~> 2.13', '>= 2.13.2'
  spec.add_dependency 'faraday-typhoeus', '~> 1.1'

  # Before upgrading, check this:
  # https://github.com/gbaptista/gemini-ai/pull/10
  spec.add_dependency 'googleauth', '~> 1.8'

  spec.add_dependency 'typhoeus', '~> 1.4', '>= 1.4.1'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
