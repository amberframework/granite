require "json"
require "uuid"

module Granite::Fields
  alias SupportedArrayTypes = Array(String) | Array(Int16) | Array(Int32) | Array(Int64) | Array(Float32) | Array(Float64) | Array(Bool)
  alias Type = DB::Any | SupportedArrayTypes | UUID
  TIME_FORMAT_REGEX = /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/

  module ClassMethods
    # All fields
    def fields : Array(String)
      {% begin %}
        {% columns = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.name.stringify) %}
        {{columns.empty? ? "[] of String".id : columns}}
      {% end %}
    end

    # Fields minus the PK
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

  # specify the fields you want to define and types
  macro field(decl, **options)
    {% raise "The type of #{@type.name}##{decl.var} cannot be a Union.  The 'field' macro declares the type as nilable by default.  Use the 'field!' macro to declare a not nilable field." if decl.type.is_a? Union %}
    {% column_type = (options[:column_type] && !options[:column_type].nil?) ? options[:column_type] : nil %}
    {% converter = (options[:converter] && !options[:converter].nil?) ? options[:converter] : nil %}
    @[Granite::Column(column_type: {{column_type}}, converter: {{converter}})]
    property {{decl.var}} : {{decl.type}}? {% if decl.value %} = {{decl.value}} {% end %}

    def {{decl.var.id}}! : {{decl.type}}
      raise NilAssertionError.new {{@type.name.stringify}} + "#" + {{decl.var.stringify}} + " cannot be nil" if @{{decl.var}}.nil?
      @{{decl.var}}.not_nil!
    end
  end

  # specify the raise-on-nil fields you want to define and types
  macro field!(decl, **options)
    {% raise "The type of #{@type.name}##{decl.var} cannot be a Union.  The 'field' macro declares the type as nilable by default.  Use the 'field!' macro to declare a not nilable field." if decl.type.is_a? Union %}
    {% column_type = (options[:column_type] && !options[:column_type].nil?) ? options[:column_type] : nil %}
    {% converter = (options[:converter] && !options[:converter].nil?) ? options[:converter] : nil %}
    @[Granite::Column(column_type: {{column_type}}, converter: {{converter}})]
    property {{decl.var}} : {{decl.type}}? {% if decl.value %} = {{decl.value}} {% end %}

    def {{decl.var.id}} : {{decl.type}}
      raise NilAssertionError.new {{@type.name.stringify}} + "#" + {{decl.var.stringify}} + " cannot be nil" if @{{decl.var}}.nil?
      @{{decl.var}}.not_nil!
    end
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    field created_at : Time
    field updated_at : Time
  end

  def to_h
    fields = {} of String => Type

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
      if hash.has_key?({{column.stringify}}) && !hash[{{column.stringify}}].nil?
        val = Granite::Type.convert_type hash[{{column.stringify}}], {{column.type}}
        if !val.is_a? {{column.type}}
          errors << Granite::Error.new({{column.name.stringify}}, "Expected {{column.id}} to be {{column.type}} but got #{typeof(val)}.")
        else
          @{{column.id}} = val
        end
      end
    {% end %}
    self
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
      {{primary_key.id}}
    {% end %}
  end
end
