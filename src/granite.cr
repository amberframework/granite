require "yaml"
require "db"
require "log"

module Granite
  Log = ::Log.for("granite")

  TIME_ZONE       = "UTC"
  DATETIME_FORMAT = "%F %X%z"

  alias ModelArgs = Hash(Symbol | String, Granite::Columns::Type)

  annotation Column; end
  annotation Table; end
end

require "./granite/base"
