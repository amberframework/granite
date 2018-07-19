Granite::Settings.adapters << Granite::Adapter::Mysql.new({name: "mysql", url: ENV["MYSQL_DATABASE_URL"]})
Granite::Settings.adapters << Granite::Adapter::Pg.new({name: "pg", url: ENV["PG_DATABASE_URL"]})
Granite::Settings.adapters << Granite::Adapter::Sqlite.new({name: "sqlite", url: ENV["SQLITE_DATABASE_URL"]})

require "spec"

module GraniteExample
  ADAPTERS = ["pg", "mysql", "sqlite"]
end

require "../src/granite"
require "./spec_models"
require "./mocks/**"

Granite::Settings.logger = ::Logger.new(nil)
