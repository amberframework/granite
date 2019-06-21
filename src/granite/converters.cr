module Granite::Converters
  module Uuid(T)
    extend self

    def to_db(value : ::UUID?) : Granite::Fields::Type
      return nil if value.nil?
      {% if T == String %}
        value.to_s
      {% elsif T == Bytes %}
        value.to_slice.dup
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

  module Enum(E, T)
    extend self

    def to_db(value : E?) : Granite::Fields::Type
      return nil if value.nil?
      {% if T <= Number %}
        value.to_i
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
        E.from_value? value
      {% elsif T == String %}
        E.parse? value
      {% elsif T == Bytes %}
        E.parse? String.new value
      {% else %}
        {% raise "#{@type.name}#from_rs does not support #{T} yet." %}
      {% end %}
    end
  end

  module Json(M, T)
    extend self

    def to_db(value : M?) : Granite::Fields::Type
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

  module PgNumeric
    extend self

    def self.to_db(value) : Granite::Fields::Type
      value ? value : nil
    end

    def self.from_rs(result : ::DB::ResultSet) : Float64?
      result.read(::PG::Numeric?).try &.to_f
    end
  end
end
