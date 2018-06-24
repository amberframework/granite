Granite::Settings.database_url["mysql"] = ENV["MYSQL_DATABASE_URL"]
Granite::Settings.database_url["pg"] = ENV["PG_DATABASE_URL"]
Granite::Settings.database_url["sqlite"] = ENV["SQLITE_DATABASE_URL"]

require "spec"

module GraniteExample
  ADAPTERS = ["pg", "mysql", "sqlite"]
end

require "../src/granite"
require "./spec_models"
require "./mocks/**"

Granite::Settings.logger = ::Logger.new(nil)
