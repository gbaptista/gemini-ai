# frozen_string_literal: true

require_relative '../../static/gem'
require_relative '../../controllers/client'

module Gemini
  def self.new(...)
    Controllers::Client.new(...)
  end

  def self.version
    Gemini::GEM[:version]
  end
end
