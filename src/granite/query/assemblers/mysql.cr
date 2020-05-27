# Query runner which finalizes a query and runs it.
# This will likely require adapter specific subclassing :[.
module Granite::Query::Assembler
  class Mysql(Model) < Base(Model)
    @placeholder = "?"

    def add_parameter(value : Granite::Columns::Type) : String
      @numbered_parameters << value
      "?"
    end
  end
end
