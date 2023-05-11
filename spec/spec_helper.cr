require "mysql"
require "pg"
require "sqlite3"

CURRENT_ADAPTER     = ENV["CURRENT_ADAPTER"]
ADAPTER_URL         = ENV["#{CURRENT_ADAPTER.upcase}_DATABASE_URL"]
ADAPTER_REPLICA_URL = ENV["#{CURRENT_ADAPTER.upcase}_REPLICA_URL"]? || ADAPTER_URL

case CURRENT_ADAPTER
when "pg"
  Granite::Connections << Granite::Adapter::Pg.new(name: CURRENT_ADAPTER, url: ADAPTER_URL)
  Granite::Connections.<<(name: "pg_with_replica", writer: ADAPTER_URL, reader: ADAPTER_REPLICA_URL, adapter_type: Granite::Adapter::Pg)
when "mysql"
  Granite::Connections << Granite::Adapter::Mysql.new(name: CURRENT_ADAPTER, url: ADAPTER_URL)
  Granite::Connections.<<(name: "mysql_with_replica", writer: ADAPTER_URL, reader: ADAPTER_REPLICA_URL, adapter_type: Granite::Adapter::Mysql)
when "sqlite"
  Granite::Connections << Granite::Adapter::Sqlite.new(name: CURRENT_ADAPTER, url: ADAPTER_URL)
  Granite::Connections.<<(name: "sqlite_with_replica", writer: ADAPTER_URL, reader: ADAPTER_REPLICA_URL, adapter_type: Granite::Adapter::Sqlite)
when Nil
  raise "Please set CURRENT_ADAPTER"
else
  raise "Unknown adapter #{CURRENT_ADAPTER}"
end

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
