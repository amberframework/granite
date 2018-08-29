require "logger"

module Granite
  class Settings
    property logger : Logger

    def initialize
      @logger = Logger.new nil
      @logger.progname = "Granite"
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
