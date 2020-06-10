module Granite::Select
  struct Container
    property custom : String?
    getter table_name, fields

    def initialize(@custom = nil, @table_name = "", @fields = [] of String)
    end
  end

  macro select_statement(text)
    self.select.custom = {{text.strip}}

    def self.select
      self.select.custom
    end
  end

  def select_container : Container
    self.select
  end
end
