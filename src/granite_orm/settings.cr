module Granite::ORM
  class Settings
    property database_url : String? = nil
  end

  def self.settings
    @@settings ||= Settings.new
  end
end
