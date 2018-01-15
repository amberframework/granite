require "logger"

module Granite::ORM
  class Settings
    property database_url : String? = nil
    property logger : Logger
    property? colorize : Bool = true

    def initialize
      @logger = Logger.new STDOUT
      @logger.progname = "Granite"
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
