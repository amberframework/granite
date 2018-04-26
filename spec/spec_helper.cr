require "spec"

module GraniteExample
  ADAPTERS = ["pg", "mysql", "sqlite"]
end

require "../src/granite_orm"
require "./spec_models"
require "./mocks/**"

Granite::ORM.settings.logger = ::Logger.new(nil)
