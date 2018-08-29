require "mysql"
require "pg"
require "sqlite3"

Granite::Adapters << Granite::Adapter::Mysql.new({name: "mysql", url: ENV["MYSQL_DATABASE_URL"]})
Granite::Adapters << Granite::Adapter::Pg.new({name: "pg", url: ENV["PG_DATABASE_URL"]})
Granite::Adapters << Granite::Adapter::Sqlite.new({name: "sqlite", url: ENV["SQLITE_DATABASE_URL"]})

require "spec"
require "../src/granite"
require "../src/adapter/**"
require "./spec_models"
require "./mocks/**"
