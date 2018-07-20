require "logger"

module Granite
  class Settings
    class_getter adapters = [] of Granite::Adapter::Base
    class_property logger = Logger.new STDOUT

    def initialize
      @@logger.progname = "Granite"
    end
  end
end
