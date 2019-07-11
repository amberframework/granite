require "mysql"
require "pg"
require "sqlite3"

Granite::Connections << Granite::Adapter::Mysql.new(name: "mysql", url: ENV["MYSQL_DATABASE_URL"])
Granite::Connections << Granite::Adapter::Pg.new(name: "pg", url: ENV["PG_DATABASE_URL"])
Granite::Connections << Granite::Adapter::Sqlite.new(name: "sqlite", url: ENV["SQLITE_DATABASE_URL"])

Spec.before_each do
  Granite.settings.default_timezone = Granite::TIME_ZONE
end

require "spec"
require "../src/granite"
require "../src/adapter/**"
require "./spec_models"
require "./mocks/**"
