require "json"
require "uuid"

module Granite::Columns
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

    # Raise an exception if the delc type has more than 2 union types or if it has 2 types without nil
    # This prevents having a column typed to String | Int32 etc.
    {% if type.is_a?(Union) && (type.types.size > 2 || (type.types.size == 2 && !type.types.any?(&.resolve.nilable?))) %}
      {% raise "The type of #{@type.name}##{decl.var} cannot be a Union.  The 'field' macro declares the type as nilable by default.  Use the 'field!' macro to declare a not nilable field." %}
    {% end %}

    {% column_type = (options[:column_type] && !options[:column_type].nil?) ? options[:column_type] : nil %}
    {% converter = (options[:converter] && !options[:converter].nil?) ? options[:converter] : nil %}
    {% primary = (options[:primary] && !options[:primary].nil?) ? options[:primary] : false %}
    {% auto = (options[:auto] && !options[:auto].nil?) ? options[:auto] : false %}
    {% auto = (!options || (options && options[:auto] == nil)) && primary %}

    {% nilable = (type.is_a?(Path) ? type.resolve.nilable? : (type.is_a?(Union) ? type.types.any?(&.resolve.nilable?) : (type.is_a?(Generic) ? type.resolve.nilable? : type.nilable?))) %}

    @[Granite::Column(column_type: {{column_type}}, converter: {{converter}}, auto: {{auto}}, primary: {{primary}}, nilable: {{nilable}})]
    @{{decl.var}} : {{decl.type}}? {% if !decl.value.is_a? Nop %} = {{decl.value}} {% end %}

    # Nilable or primary, define normal and raise on nil getters
    {% if nilable || primary %}
      def {{decl.var.id}}=(@{{decl.var.id}} : {{type.id}}?); end

      def {{decl.var.id}} : {{decl.type}}?
        @{{decl.var}}
      end

      def {{decl.var.id}}! : {{type.id}}
        raise NilAssertionError.new {{@type.name.stringify}} + "#" + {{decl.var.stringify}} + " cannot be nil" if @{{decl.var}}.nil?
        @{{decl.var}}.not_nil!
      end
    # Not nilable, define raise on nil getter
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
