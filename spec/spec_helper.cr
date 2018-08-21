require "spec"

module GraniteExample
  ADAPTERS = ["pg", "mysql", "sqlite"]
  CURRENT_ADAPTER = {{ env("CURRENT_ADAPTER") }} 
end

require "../src/granite"
require "../src/adapter/**"
require "./spec_models"
require "./mocks/**"

puts GraniteExample::CURRENT_ADAPTER

Granite.settings.logger = ::Logger.new(nil)
