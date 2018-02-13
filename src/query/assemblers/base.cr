module Query::Assembler
  abstract class Base(Model)
    def initialize(@query : Builder(Model))
      @numbered_parameters = [] of DB::Any
      @aggregate_fields = [] of String
    end

    def add_parameter(value : DB::Any) : String
      @numbered_parameters << value
      "$#{@numbered_parameters.size}"
    end

    def numbered_parameters
      @numbered_parameters
    end

    def add_aggregate_field(name : String)
      @aggregate_fields << name
    end

    def table_name
      Model.table_name
    end

    def field_list
      [Model.primary_name, Model.fields].flatten.join ", "
    end

    abstract def count : Int64
    abstract def first(n : Int32 = 1) : Array(Model)
    abstract def delete
  end
end
