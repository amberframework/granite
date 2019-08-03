require "yaml"
require "db"

module Granite
  TIME_ZONE       = "UTC"
  DATETIME_FORMAT = "%F %X%z"

  alias ModelArgs = Hash(Symbol | String, Granite::Columns::Type)

  annotation Column; end
  annotation Table; end
end

require "./granite/base"
