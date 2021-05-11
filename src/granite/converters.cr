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
end
