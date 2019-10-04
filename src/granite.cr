require "yaml"
require "db"

module Granite
  TIME_ZONE       = "UTC"
  DATETIME_FORMAT = "%F %X%z"

  annotation Column; end
  annotation Table; end
end

require "./granite/base"
