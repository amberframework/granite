require "logger"

module Granite
  class Settings
    property logger : Logger
    property default_timezone : Time::Location

    def initialize
      @logger = Logger.new nil
      @logger.progname = "Granite"

      @default_timezone = Time::Location.load(Granite::TIME_ZONE)
    end

    def default_timezone=(name : String)
      @default_timezone = Time::Location.load(name)
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
