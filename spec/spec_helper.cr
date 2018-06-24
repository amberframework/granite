Granite.settings.database_url = ENV["MYSQL_DATABASE_URL"]
Granite.settings.database_url = ENV["PG_DATABASE_URL"]
Granite.settings.database_url = ENV["SQLITE_DATABASE_URL"]

require "spec"

module GraniteExample
  ADAPTERS = ["pg", "mysql", "sqlite"]
end

require "../src/granite"
require "./spec_models"
require "./mocks/**"

Granite.settings.logger = ::Logger.new(nil)
