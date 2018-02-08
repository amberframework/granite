module Query::Assembler
  abstract class Base(T)
    def initialize(@query : Builder(T))
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
      T.table_name
    end

    def field_list
      [T.primary_name, T.fields].flatten.join ", "
    end

    abstract def count : Int64
    abstract def first(n : Int32 = 1) : Array(T)
    abstract def delete
  end
end
