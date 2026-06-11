module Granite::Query::Assembler
  class Sqlite(Model) < Base(Model)
    @placeholder = "?"

    @[TargetFeature("+avx2")]
    def add_parameter(value : Granite::Columns::Type) : String
      @numbered_parameters << value
      "?"
    end
  end
end
