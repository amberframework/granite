module Granite::Type
  extend self

  # :nodoc:
  PRIMITIVES = {
    Int8    => ".read",
    Int16   => ".read",
    Int32   => ".read",
    Int64   => ".read",
    UInt8   => ".read",
    UInt16  => ".read",
    UInt32  => ".read",
    UInt64  => ".read",
    Float32 => ".read",
    Float64 => ".read",
    Bool    => ".read",
    String  => ".read",
    Time    => ".read",
  }

  {% for type, method in PRIMITIVES %}
    # Converts a `DB::ResultSet` to `{{type}}`.
    def from_rs(result : DB::ResultSet, t : {{type.id}}.class) : {{type.id}}
      result{{method.id}} {{type}}
    end

    # Converts a `DB::ResultSet` to `{{type}}?`.
    def from_rs(result : DB::ResultSet, t : {{type.id}}?.class) : {{type.id}}?
      result{{method.id}} {{type}}?
    end
  {% end %}

  def convert_type(value, type)
    value
  end

  def convert_type(value, type : Bool?.class) : Bool
    ["1", "yes", "true", true, 1].includes?(value)
  end
end
