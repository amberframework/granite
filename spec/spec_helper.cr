require "mysql"
require "pg"
require "sqlite3"

Granite::Connections << Granite::Adapter::Mysql.new(name: "mysql", url: ENV["MYSQL_DATABASE_URL"])
Granite::Connections << Granite::Adapter::Pg.new(name: "pg", url: ENV["PG_DATABASE_URL"])
Granite::Connections << Granite::Adapter::Sqlite.new(name: "sqlite", url: ENV["SQLITE_DATABASE_URL"])

# Connections with replicas
# TODO: Experiment to find a better API.
Granite::Connections.<<(name: "sqlite_with_replica", writer: ENV["SQLITE_DATABASE_URL"], reader: ENV["SQLITE_REPLICA_URL"], adapter_type: Granite::Adapter::Sqlite)
Granite::Connections.<<(name: "mysql_with_replica", writer: ENV["MYSQL_DATABASE_URL"], reader: ENV["MYSQL_REPLICA_URL"], adapter_type: Granite::Adapter::Mysql)
Granite::Connections.<<(name: "pg_with_replica", writer: ENV["PG_DATABASE_URL"], reader: ENV["PG_REPLICA_URL"], adapter_type: Granite::Adapter::Pg)

require "spec"
require "../src/granite"
require "../src/adapter/**"
require "./spec_models"
require "./mocks/**"

Spec.before_suite do
  Granite.settings.default_timezone = Granite::TIME_ZONE
  {% if flag?(:spec_logs) %}
    ::Log.builder.bind(
      # source: "spec.client",
      source: "*",
      level: ::Log::Severity::Trace,
      backend: ::Log::IOBackend.new(STDOUT, dispatcher: :sync),
    )
  {% end %}
end

Spec.before_each do
  # I have no idea why this is needed, but it is.
  Granite.settings.default_timezone = Granite::TIME_ZONE
end

{% if env("CURRENT_ADAPTER") == "mysql" && !flag?(:issue_473) %}
  Spec.after_each do
    # https://github.com/amberframework/granite/issues/473
    Granite::Connections["mysql"].not_nil![:writer].try &.database.pool.close
  end
{% end %}
