require "json"

module Granite::Fields
  alias SupportedArrayTypes = Array(String) | Array(Int16) | Array(Int32) | Array(Int64) | Array(Float32) | Array(Float64) | Array(Bool)
  alias Type = DB::Any | SupportedArrayTypes
  TIME_FORMAT_REGEX = /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/

  macro included
    macro inherited
      disable_granite_docs? CONTENT_FIELDS = {} of Nil => Nil
      disable_granite_docs? FIELDS = {} of Nil => Nil
    end
  end

  # specify the fields you want to define and types
  macro field(decl, **options)
    {% CONTENT_FIELDS[decl.var] = options || {} of Nil => Nil %}
    {% CONTENT_FIELDS[decl.var][:type] = decl.type %}
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    field created_at : Time
    field updated_at : Time
  end

  macro __process_fields
    # merge PK and CONTENT_FIELDS into FIELDS
    {% FIELDS[PRIMARY[:name]] = PRIMARY %}
    {% for name, options in CONTENT_FIELDS %}
      {% FIELDS[name] = options %}
    {% end %}

    # Create the properties
    {% for name, options in FIELDS %}
      {% type = options[:type] %}

      # Override options after setting required variables
      # to get to the user supplied options
      {% if options[:options] %}
        {% options = options[:options] %}
      {% end %}

      # Set each user supplied annotation on the property
      {% if options[:annotations] %}
        {% for ann in options[:annotations] %}
          {{ann.id}}
        {% end %}
      {% end %}

      # Apply JSON/YAML serialization option annotations
      {% if options[:json_options] %}
         @[JSON::Field({{**options[:json_options]}})]
      {% end %}
      {% if options[:yaml_options] %}
         @[YAML::Field({{**options[:yaml_options]}})]
      {% end %}

      # Apply property comment if exists
      {% if options[:comment] %}
         {{options[:comment].id}}
      {% end %}
      property {{name.id}} : {{type.id}}
    {% end %}

    # keep a hash of the fields to be used for mapping
    disable_granite_docs? def self.fields : Array(String)
      @@fields ||= {{ FIELDS.empty? ? "[] of String".id : FIELDS.keys.map(&.id.stringify) }}
    end

    disable_granite_docs? def self.content_fields : Array(String)
      @@content_fields ||= {{ CONTENT_FIELDS.empty? ? "[] of String".id : CONTENT_FIELDS.keys.map(&.id.stringify) }}
    end

    # keep a hash of the params that will be passed to the adapter.
    disable_granite_docs? def content_values
      parsed_params = [] of Type
      {% for name, options in CONTENT_FIELDS %}
        parsed_params << {{name.id}}
      {% end %}
      return parsed_params
    end

    disable_granite_docs? def to_h
      fields = {} of String => Type

      {% for name, options in FIELDS %}
        {% type = options[:type] %}
        {% if type.id == Time.id %}
          fields["{{name}}"] = {{name.id}}.try(&.to_s(Granite::DATETIME_FORMAT))
        {% elsif type.id == Slice.id %}
          fields["{{name}}"] = {{name.id}}.try(&.to_s(""))
        {% else %}
          fields["{{name}}"] = {{name.id}}
        {% end %}
      {% end %}

      return fields
    end

    disable_granite_docs? def read_attribute(attribute_name : Symbol | String) : DB::Any
      {% begin %}
        case attribute_name.to_s
        {% for name, options in FIELDS %}
          when "{{ name }}" then @{{ name.id }}
        {% end %}
        else
          raise "Cannot read attribute #{attribute_name}, invalid attribute"
        end
      {% end %}
    end

    disable_granite_docs? def set_attributes(args : Hash(String | Symbol, Type))
      args.each do |k, v|
        cast_to_field(k, v.as(Type))
      end
    end

    disable_granite_docs? def set_attributes(**args)
      set_attributes(args.to_h)
    end

    # Casts params and sets fields
    private def cast_to_field(name, value : Type)
      {% unless FIELDS.empty? %}
        case name.to_s
          {% for _name, options in FIELDS %}
            {% type = options[:type] %}
          when "{{_name.id}}"
            if "{{_name.id}}" == "{{PRIMARY[:name]}}"
              {% unless PRIMARY[:auto] %}
                @{{PRIMARY[:name]}} = value.as({{PRIMARY[:type]}})
              {% end %}
              return
            end

            return @{{_name.id}} = nil if value.nil?
            {% if type.id == Int32.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_i32(strict: false) : value.is_a?(Int64) ? value.to_i32 : value.as(Int32)
            {% elsif type.id == Int64.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_i64(strict: false) : value.as(Int64)
            {% elsif type.stringify == "Int64 | Nil" %}
              @{{_name.id}} = "foo"
            {% elsif type.id == Float32.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_f32(strict: false) : value.is_a?(Float64) ? value.to_f32 : value.as(Float32)
            {% elsif type.id == Float64.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_f64(strict: false) : value.as(Float64)
            {% elsif type.id == Bool.id %}
              @{{_name.id}} = ["1", "yes", "true", true].includes?(value)
            {% elsif type.id == Time.id %}
              if value.is_a?(Time)
                @{{_name.id}} = value
              elsif value.to_s =~ TIME_FORMAT_REGEX
                @{{_name.id}} = Time.parse_utc(value.to_s, Granite::DATETIME_FORMAT)
              end
            {% else %}
              @{{_name.id}} = value.to_s
            {% end %}
          {% end %}
        end
      {% end %}
    rescue ex
      errors << Granite::Error.new(name, ex.message)
    end
  end
end
