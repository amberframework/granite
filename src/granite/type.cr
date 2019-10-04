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
end
