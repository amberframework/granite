require "logger"

module Granite
  class Settings
    class_property database_url = {} of String => String
    class_property logger = Logger.new STDOUT

    def initialize
      @@logger.progname = "Granite"
    end
  end
end
