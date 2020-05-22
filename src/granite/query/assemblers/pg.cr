# Query runner which finalizes a query and runs it.
# This will likely require adapter specific subclassing :[.
module Granite::Query::Assembler
  class Pg(Model) < Base(Model)
    @placeholder = "$"

    def add_parameter(value : Granite::Columns::Type) : String
      @numbered_parameters << value
      "$#{@numbered_parameters.size}"
    end
  end
end
