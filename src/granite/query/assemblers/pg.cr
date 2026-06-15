# Query runner which finalizes a query and runs it.
# This will likely require adapter specific subclassing :[.
module Granite::Query::Assembler
  class Pg(Model) < Base(Model)
    QUOTING_CHAR = '"'
    @placeholder = "$"

    def field_list
      # Override this method to quote the fields as upper case characters
      # get converted to lower case in PG, which we do not want.
      [Model.fields].flatten.map{ |field| "#{quote(field)}" }.join ", "
    end

    def add_parameter(value : Granite::Columns::Type) : String
      @numbered_parameters << value
      "$#{@numbered_parameters.size}"
    end
  end
end
