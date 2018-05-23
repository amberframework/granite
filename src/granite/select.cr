module Granite::Select
  struct Container
    property custom
    getter table_name, fields

    def initialize(@custom = "", @table_name = "", @fields = [] of String)
    end
  end

  macro query(text)
    @@select.custom = {{text.strip}}

    def self.select
      @@select.custom
    end
  end

  macro __process_select
    @@select = Container.new(table_name: @@table_name, fields: fields)
  end
end
