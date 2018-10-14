module Granite::Query::Assembler
  class Sqlite(Model) < Base(Model)
    def add_parameter(value : DB::Any) : String
      @numbered_parameters << value
      "?"
    end
  end
end
