module Granite::Converters
  # Converts a `UUID` to/from a database column of type `T`.
  #
  # Valid types for `T` include: `String`, and `Bytes`.
  module Uuid(T)
    extend self

    def to_db(value : ::UUID?) : Granite::Columns::Type
      return nil if value.nil?
      {% if T == String %}
        value.to_s
      {% elsif T == Bytes %}
        # we need a heap allocated slice
        v = value.bytes.each.to_a
        Slice.new(v.to_unsafe, v.size)
      {% else %}
        {% raise "#{@type.name}#to_db does not support #{T} yet." %}
      {% end %}
    end

    def from_rs(result : ::DB::ResultSet) : ::UUID?
      value = result.read(T?)
      return nil if value.nil?
      {% if T == String || T == Bytes %}
        ::UUID.new value
      {% else %}
        {% raise "#{@type.name}#from_rs does not support #{T} yet." %}
      {% end %}
    end
  end

  # Converts an Enum of type `E` to/from a database column of type `T`.
  #
  # Valid types for `T` include: `Number`, `String`, and `Bytes`.
  module Enum(E, T)
    extend self

    def to_db(value : E?) : Granite::Columns::Type
      return nil if value.nil?
      {% if T <= Number %}
        value.to_i64
      {% elsif T == String || T == Bytes %}
        value.to_s
      {% else %}
        {% raise "#{@type.name}#to_db does not support #{T} yet." %}
      {% end %}
    end

    def from_rs(result : ::DB::ResultSet) : E?
      value = result.read(T?)
      return nil if value.nil?
      {% if T <= Number %}
        E.from_value? value.to_i64
      {% elsif T == String %}
        E.parse? value
      {% elsif T == Bytes %}
        E.parse? String.new value
      {% else %}
        {% raise "#{@type.name}#from_rs does not support #{T} yet." %}
      {% end %}
    end
  end

  # Converts an `Object` of type `M` to/from a database column of type `T`.
  #
  # Valid types for `T` include: `String`, `JSON::Any`, and `Bytes`.
  #
  # NOTE: `M` must implement `#to_json` and `.from_json` methods.
  module Json(M, T)
    extend self

    def to_db(value : M?) : Granite::Columns::Type
      return nil if value.nil?
      {% if T == String || T == JSON::Any %}
        value.to_json
      {% elsif T == Bytes %}
        value.to_json.to_slice
      {% else %}
        {% raise "#{@type.name}#to_db does not support #{T} yet." %}
      {% end %}
    end

    def from_rs(result : ::DB::ResultSet) : M?
      value = result.read(T?)
      return nil if value.nil?
      {% if T == JSON::Any %}
        M.from_json(value.to_json)
      {% elsif T == String %}
        M.from_json value
      {% elsif T == Bytes %}
        M.from_json String.new value
      {% else %}
        {% raise "#{@type.name}#from_rs does not support #{T} yet." %}
      {% end %}
    end
  end

  # We may want the JSON object as a string to parse later on
  module JsonString
    extend self

    def to_db(value) : Granite::Columns::Type
      return nil if value.nil?
      value.to_json
    end

    def from_rs(result : ::DB::ResultSet) : String
      value = result.read(JSON::Any).to_json
      
      # We want to remove any escape characters so that the string can be parsed correctly
      value = value.gsub("\\", "")

      # If present, we want to strip off the starting and ending quotes
      value = value[1..-2] if value[0] == "\"" && value[-1] == "\""
      value
    end
  end

  # Converters a `PG::Numeric` value into a `Float64`.
  module PgNumeric
    extend self

    def self.to_db(value) : Granite::Columns::Type
      value ? value : nil
    end

    def self.from_rs(result : ::DB::ResultSet) : Float64?
      result.read(::PG::Numeric?).try &.to_f
    end
  end

  # Converts a `Slice(UInt8)/Bytes` value into a `String`. Usually for PG Enums
  module EnumSlice
    extend self

    def self.to_db(value) : Granite::Columns::Type
      value
    end

    def self.from_rs(result : ::DB::ResultSet) : String
      String.new result.read Slice(UInt8)
    end
  end

  module PgEnumArray(E)
    extend self

    # This is specific to PG due to the way the array is formed as a string
    def to_db(value : Array(E)) : Granite::Columns::Type
      "{#{value.map{ |value| "\"#{value.to_s}\"" }.join(",")}}"
    end

    # The PG adapter is unable to read an array of Enums/Bytes
    # Therefore, convert the result to string and attempt to match the enums
    def from_rs(result : ::DB::ResultSet) : Array(E)
      result_string = String.new result.read(Slice(UInt8))
      result_enums = Array(E).new
      E.each do |enum_value|
        result_enums << enum_value if result_string.includes?(enum_value.to_s)
      end
      result_enums
    end
  end
end
