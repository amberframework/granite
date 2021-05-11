module Granite::Query::Assembler
  class Sqlite(Model) < Base(Model)
    @placeholder = "?"

    def add_parameter(value : Granite::Columns::Type) : String
      @numbered_parameters << value
      "?"
    end
  end
end
