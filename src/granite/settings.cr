require "logger"

module Granite
  class Settings
    property logger = Logger.new STDOUT
    getter adapters = {} of String => String

    def initialize
      @logger.progname = "Granite"
    end

    def database_url=(database_url : String)
      if adapter_name = database_url.match(/(\w+)\:/)
        case adapter_name[1]
        when "postgres" then @adapters["pg"] = database_url
        when "sqlite3"  then @adapters["sqlite"] = database_url
        when "mysql"    then @adapters["mysql"] = database_url
        else                 raise "Unexpected adapter: '#{adapter_name[1]}'"
        end
      else
        raise "Invalid connection string"
      end
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
