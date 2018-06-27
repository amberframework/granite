module Granite::Select
  struct Container
    property custom : String?
    getter table_name, fields

    def initialize(@custom = nil, @table_name = "", @fields = [] of String)
    end
  end

  macro select_statement(text)
    @@select.custom = {{text.strip}}

    def self.select
      @@select.custom
    end
  end

  macro __process_select
    @@select = Container.new(table_name: @@table_name, fields: fields)
  end
end
