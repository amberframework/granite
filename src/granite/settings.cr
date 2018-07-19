require "logger"

module Granite
  class Settings
    property logger : Logger

    def initialize
      @logger = Logger.new STDOUT
      @logger.progname = "Granite"
    end
  end

  class Adapters
    property adapters = [] of Granite::Adapter::Base

    def <<(adapter : Granite::Adapter::Base)
      @adapters << adapter
    end
  end

  def self.adapters
    @@adapters ||= Adapters.new
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
