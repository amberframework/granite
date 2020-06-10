module Granite::Select
  struct Container
    property custom : String?
    getter table_name, fields

    def initialize(@custom = nil, @table_name = "", @fields = [] of String)
    end
  end

  macro select_statement(text)
    @@select_container.custom = {{text.strip}}

    def self.select : String?
      self.select_container.custom
    end
  end
end
