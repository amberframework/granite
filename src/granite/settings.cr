module Granite
  class Settings
    property default_timezone : Time::Location = Time::Location.load(Granite::TIME_ZONE)

    def default_timezone=(name : String)
      @default_timezone = Time::Location.load(name)
    end
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
