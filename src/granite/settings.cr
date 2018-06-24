require "logger"

module Granite
  class Settings
    class_property database_url = {"mysql" => "", "pg" => "", "sqlite" => ""}
    class_property logger = Logger.new STDOUT

    def initialize
      @@logger.progname = "Granite"
    end
  end
end
