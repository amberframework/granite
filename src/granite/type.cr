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
  }

  # :nodoc:
  NUMERIC_TYPES = {
    Int8    => ".to_i8",
    Int16   => ".to_i16",
    Int32   => ".to_i",
    Int64   => ".to_i64",
    UInt8   => ".to_u8",
    UInt16  => ".to_u16",
    UInt32  => ".to_u32",
    UInt64  => ".to_u64",
    Float32 => ".to_f32",
    Float64 => ".to_f",
  }

  {% for type, method in PRIMITIVES %}
    # Converts a `DB::ResultSet` to `{{type}}`.
    def from_rs(result : DB::ResultSet, t : {{type}}.class) : {{type}}
      result{{method.id}} {{type}}
    end

    # Converts a `DB::ResultSet` to `{{type}}?`.
    def from_rs(result : DB::ResultSet, t : {{type}}?.class) : {{type}}?
      result{{method.id}} {{type}}?
    end

    # Converts an `DB::ResultSet` to `Array({{type}})`.
    def from_rs(result : DB::ResultSet, t : Array({{type}}).class) : Array({{type}})
      result{{method.id}} Array({{type}})
    end

    # Converts an `DB::ResultSet` to `Array({{type}})?`.
    def from_rs(result : DB::ResultSet, t : Array({{type}})?.class) : Array({{type}})?
      result{{method.id}} Array({{type}})?
    end
  {% end %}

  # Converts a `DB::ResultSet` to `Time`.
  def from_rs(result : DB::ResultSet, t : Time.class) : Time
    result.read(Time).in(Granite.settings.default_timezone)
  end

  # Converts a `DB::ResultSet` to `Time?`
  def from_rs(result : DB::ResultSet, t : Time?.class) : Time?
    result.read(Time?).try &.in(Granite.settings.default_timezone)
  end

  {% for type, method in NUMERIC_TYPES %}
    # Converts a `String` to `{{type}}`.
    def convert_type(value : String, t : {{type.id}}.class) : {{type.id}}
      value{{method.id}}
    end

    # Converts a `String` to `{{type}}?`.
    def convert_type(value : String, t : {{type.id}}?.class) : {{type.id}}?
      value{{method.id}}
    end
  {% end %}

  def convert_type(value, type)
    value
  end

  def convert_type(value, type : Bool?.class) : Bool
    ["1", "yes", "true", true, 1].includes?(value)
  end
end
