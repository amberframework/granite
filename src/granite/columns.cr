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

  def content_values
    parsed_params = [] of Type
    {% for column in @type.instance_vars.select { |ivar| (ann = ivar.annotation(Granite::Column)) && !ann[:primary] } %}
      {% ann = column.annotation(Granite::Column) %}
      parsed_params << {% if ann[:converter] %} {{ann[:converter]}}.to_db {{column.name.id}} {% else %} {{column.name.id}} {% end %}
    {% end %}
    parsed_params
  end

  # Defines a column *decl* with the given *options*.
  macro column(decl, **options)
    {% type = decl.type %}
    {% if type.is_a?(Union) && (type.types.size > 2 || (type.types.size == 2 && !type.types.any?(&.resolve.nilable?))) %}
      {% raise "The column #{@type.name}##{decl.var} cannot consist of a Union with a type other than `Nil`." %}
    {% end %}

    {% nilable = type.resolve.nilable? %}
    {% column_type = (options[:column_type] && !options[:column_type].nil?) ? options[:column_type] : nil %}
    {% converter = (options[:converter] && !options[:converter].nil?) ? options[:converter] : nil %}
    {% primary = (options[:primary] && !options[:primary].nil?) ? options[:primary] : false %}
    {% auto = (options[:auto] && !options[:auto].nil?) ? options[:auto] : false %}
    {% auto = (!options || (options && options[:auto] == nil)) && primary %}

    {% if primary && nilable %}
      {% raise "Primary key of #{@type} must be not-nilable" %}
    {% end %}

    @[Granite::Column(column_type: {{column_type}}, converter: {{converter}}, auto: {{auto}}, primary: {{primary}}, nilable: {{nilable}})]
    {% if !primary || (primary && !auto) %} property{{(nilable || !decl.value.is_a?(Nop) ? "" : '!').id}} {% else %} getter! {% end %} {{decl.var}} : {{decl.type}} {% unless decl.value.is_a? Nop %} = {{decl.value}} {% end %}
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    column created_at : Time?
    column updated_at : Time?
  end

  def to_h
    fields = {{"Hash(String, Union(#{@type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.type.id).splat})).new".id}}

    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
        {% ann = column.annotation(Granite::Column) %}

        {% if column.type.id == Time.id %}
          fields["{{column}}"] = {{column.id}}.try(&.in(Granite.settings.default_timezone).to_s(Granite::DATETIME_FORMAT))
        {% elsif column.type.id == Slice.id %}
          fields["{{column}}"] = {{column.id}}.try(&.to_s(""))
        {% else %}
          fields["{{column}}"] = @{{column.id}}
        {% end %}
      {% end %}

    fields
  end

  def read_attribute(attribute_name : Symbol | String) : DB::Any
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
      {{primary_key.id}}?
    {% end %}
  end
end
