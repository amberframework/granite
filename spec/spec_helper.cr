require "envy"
Envy.load

require "spec"

module GraniteExample
  ADAPTERS = ["pg", "mysql", "sqlite"]
end

require "../src/granite"
require "./spec_models"
require "./mocks/**"

Granite.settings.logger = ::Logger.new(nil)
