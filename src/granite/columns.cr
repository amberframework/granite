require "json"
require "uuid"

module Granite::Columns
  alias SupportedArrayTypes = Array(String) | Array(Int16) | Array(Int32) | Array(Int64) | Array(Float32) | Array(Float64) | Array(Bool)
  alias Type = DB::Any | SupportedArrayTypes | UUID

  module ClassMethods
    # All fields
    def fields : Array(String)
      {% begin %}
        {% columns = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.name.stringify) %}
        {{columns.empty? ? "[] of String".id : columns}}
      {% end %}
    end

    # Columns minus the PK
    def content_fields : Array(String)
      {% begin %}
        {% columns = @type.instance_vars.select { |ivar| (ann = ivar.annotation(Granite::Column)) && !ann[:primary] }.map(&.name.stringify) %}
        {{columns.empty? ? "[] of String".id : columns}}
      {% end %}
    end
  end

  def content_values : Array(Granite::Columns::Type)
    parsed_params = [] of Type
    {% for column in @type.instance_vars.select { |ivar| (ann = ivar.annotation(Granite::Column)) && !ann[:primary] } %}
      {% ann = column.annotation(Granite::Column) %}
      parsed_params << {% if ann[:converter] %} {{ann[:converter]}}.to_db {{column.name.id}} {% else %} {{column.name.id}} {% end %}
    {% end %}
    parsed_params
  end

  # Consumes the result set to set self's property values.
  def from_rs(result : DB::ResultSet) : Nil
    {% begin %}
      result.column_names.each do |col|
        case col
        {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
          {% ann = column.annotation(Granite::Column) %}
          when {{column.name.stringify}}
            @{{column.id}} = {% if ann[:converter] %}
              {{ann[:converter]}}.from_rs result
            {% else %}
              value = Granite::Type.from_rs(result, {{ann[:nilable] ? column.type : column.type.union_types.reject { |t| t == Nil }.first}})

              {% if column.has_default_value? && !column.default_value.nil? %}
                return {{column.default_value}} if value.nil?
              {% end %}

              value
            {% end %}
        {% end %}
        else
          # Skip
        end
      end
    {% end %}
  end

  # Defines a column *decl* with the given *options*.
  macro column(decl, **options)
    {% type = decl.type %}
    {% not_nilable_type = type.is_a?(Path) ? type.resolve : (type.is_a?(Union) ? type.types.reject(&.resolve.nilable?).first : (type.is_a?(Generic) ? type.resolve : type)) %}

    # Raise an exception if the delc type has more than 2 union types or if it has 2 types without nil
    # This prevents having a column typed to String | Int32 etc.
    {% if type.is_a?(Union) && (type.types.size > 2 || (type.types.size == 2 && !type.types.any?(&.resolve.nilable?))) %}
      {% raise "The column #{@type.name}##{decl.var} cannot consist of a Union with a type other than `Nil`." %}
    {% end %}

    {% column_type = (options[:column_type] && !options[:column_type].nil?) ? options[:column_type] : nil %}
    {% converter = (options[:converter] && !options[:converter].nil?) ? options[:converter] : nil %}
    {% primary = (options[:primary] && !options[:primary].nil?) ? options[:primary] : false %}
    {% auto = (options[:auto] && !options[:auto].nil?) ? options[:auto] : false %}
    {% auto = (!options || (options && options[:auto] == nil)) && primary %}

    {% nilable = (type.is_a?(Path) ? type.resolve.nilable? : (type.is_a?(Union) ? type.types.any?(&.resolve.nilable?) : (type.is_a?(Generic) ? type.resolve.nilable? : type.nilable?))) %}

    @[Granite::Column(column_type: {{column_type}}, converter: {{converter}}, auto: {{auto}}, primary: {{primary}}, nilable: {{nilable}})]
    @{{decl.var}} : {{decl.type}}? {% unless decl.value.is_a? Nop %} = {{decl.value}} {% end %}

    {% if nilable || primary %}
      def {{decl.var.id}}=(@{{decl.var.id}} : {{not_nilable_type}}?); end

      def {{decl.var.id}} : {{not_nilable_type}}?
        @{{decl.var}}
      end

      def {{decl.var.id}}! : {{not_nilable_type}}
        raise NilAssertionError.new {{@type.name.stringify}} + "#" + {{decl.var.stringify}} + " cannot be nil" if @{{decl.var}}.nil?
        @{{decl.var}}.not_nil!
      end
    {% else %}
      def {{decl.var.id}}=(@{{decl.var.id}} : {{type.id}}); end

      def {{decl.var.id}} : {{type.id}}
        raise NilAssertionError.new {{@type.name.stringify}} + "#" + {{decl.var.stringify}} + " cannot be nil" if @{{decl.var}}.nil?
        @{{decl.var}}.not_nil!
      end
    {% end %}
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    column created_at : Time?
    column updated_at : Time?
  end

  def to_h
    fields = {{"Hash(String, Union(#{@type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.type.id).splat})).new".id}}

    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
        {% if column.type.id == Time.id %}
          fields["{{column.name}}"] = {{column.name.id}}.try(&.in(Granite.settings.default_timezone).to_s(Granite::DATETIME_FORMAT))
        {% elsif column.type.id == Slice.id %}
          fields["{{column.name}}"] = {{column.name.id}}.try(&.to_s(""))
        {% else %}
          fields["{{column.name}}"] = {{column.name.id}}
        {% end %}
      {% end %}

    fields
  end

  def set_attributes(hash : Hash(String | Symbol, Type)) : self
    {% for column in @type.instance_vars.select { |ivar| (ann = ivar.annotation(Granite::Column)) && (!ann[:primary] || (ann[:primary] && ann[:auto] == false)) } %}
      if hash.has_key?({{column.stringify}})
        begin
          val = Granite::Type.convert_type hash[{{column.stringify}}], {{column.type}}
        rescue ex : ArgumentError
          error =  Granite::ConversionError.new({{column.name.stringify}}, ex.message)
        end

        if !val.is_a? {{column.type}}
          error = Granite::ConversionError.new({{column.name.stringify}}, "Expected {{column.id}} to be {{column.type}} but got #{typeof(val)}.")
        else
          @{{column}} = val
        end

        errors << error if error
      end
    {% end %}
    self
  end

  def read_attribute(attribute_name : Symbol | String) : Type
    {% begin %}
      case attribute_name.to_s
      {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
        when "{{ column.name }}" then @{{ column.name.id }}
      {% end %}
      else
        raise "Cannot read attribute #{attribute_name}, invalid attribute"
      end
    {% end %}
  end

  def primary_key_value
    {% begin %}
      {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
      {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
      {{primary_key.id}}
    {% end %}
  end
end
