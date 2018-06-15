require "json"

module Granite::Fields
  alias Type = DB::Any | JSON::Any
  TIME_FORMAT_REGEX = /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/

  macro included
    macro inherited
      CONTENT_FIELDS = {} of Nil => Nil
      FIELDS = {} of Nil => Nil
    end
  end

  # specify the fields you want to define and types
  macro field(decl, **options)
    {% CONTENT_FIELDS[decl.var] = options || {} of Nil => Nil %}
    {% CONTENT_FIELDS[decl.var][:type] = decl.type %}
  end

  # specify the raise-on-nil fields you want to define and types
  macro field!(decl, **options)
    field {{decl}}, {{options.double_splat(", ")}}raise_on_nil: true
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
      {% suffixes = options[:raise_on_nil] ? ["?", ""] : ["", "!"] %}
      property{{suffixes[0].id}} {{name.id}} : Union({{type.id}} | Nil)
      def {{name.id}}{{suffixes[1].id}}
        raise {{@type.name.stringify}} + "#" + {{name.stringify}} + " cannot be nil" if @{{name.id}}.nil?
        @{{name.id}}.not_nil!
      end
    {% end %}

    # keep a hash of the fields to be used for mapping
    def self.fields : Array(String)
      @@fields ||= {{ FIELDS.empty? ? "[] of String".id : FIELDS.keys.map(&.id.stringify) }}
    end

    def self.content_fields : Array(String)
      @@content_fields ||= {{ CONTENT_FIELDS.empty? ? "[] of String".id : CONTENT_FIELDS.keys.map(&.id.stringify) }}
    end

    # keep a hash of the params that will be passed to the adapter.
    def content_values
      parsed_params = [] of DB::Any
      {% for name, options in CONTENT_FIELDS %}
        {% if options[:type].id == Time.id %}
          parsed_params << {{name.id}}.try(&.to_s("%F %X"))
        {% else %}
          parsed_params << {{name.id}}
        {% end %}
      {% end %}
      return parsed_params
    end

    def to_h
      fields = {} of String => DB::Any

      {% for name, options in FIELDS %}
        {% type = options[:type] %}
        {% if type.id == Time.id %}
          fields["{{name}}"] = {{name.id}}.try(&.to_s("%F %X"))
        {% elsif type.id == Slice.id %}
          fields["{{name}}"] = {{name.id}}.try(&.to_s(""))
        {% else %}
          fields["{{name}}"] = {{name.id}}
        {% end %}
      {% end %}

      return fields
    end

    def to_json(json : JSON::Builder)
      json.object do
        {% for name, options in FIELDS %}
          {% type = options[:type] %}
          %field, %value = "{{name.id}}", {{name.id}}
          {% if type.id == Time.id %}
            json.field %field, %value.try(&.to_s("%F %X"))
          {% elsif type.id == Slice.id %}
            json.field %field, %value.id.try(&.to_s(""))
          {% else %}
            json.field %field, %value
          {% end %}
        {% end %}
      end
    end

    def set_attributes(args : Hash(String | Symbol, Type))
      args.each do |k, v|
        cast_to_field(k, v.as(Type))
      end
    end

    def set_attributes(attributes : JSON::Any)
      set_attributes(attributes.as_h)
    end

    def set_attributes(**args)
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
              {% if !PRIMARY[:auto] %}
                @{{PRIMARY[:name]}} = value.is_a?(JSON::Any) ? value.raw.as({{PRIMARY[:type]}}) : value.as({{PRIMARY[:type]}})
              {% end %}
              return
            end

            return @{{_name.id}} = nil if value.nil?
            {% if type.id == Int32.id %}
              @{{_name.id}} = value.is_a?(JSON::Any) ? value.as_i : value.is_a?(String) ? value.to_i32(strict: false) : value.is_a?(Int64) ? value.to_i32 : value.as(Int32)
            {% elsif type.id == Int64.id %}
              @{{_name.id}} = value.is_a?(JSON::Any) ? value.as_i64 : value.is_a?(String) ? value.to_i64(strict: false) : value.as(Int64)
            {% elsif type.id == Float32.id %}
              @{{_name.id}} = value.is_a?(JSON::Any) ? value.as_f32 : value.is_a?(String) ? value.to_f32(strict: false) : value.is_a?(Float64) ? value.to_f32 : value.as(Float32)
            {% elsif type.id == Float64.id %}
              @{{_name.id}} = value.is_a?(JSON::Any) ? value.as_f : value.is_a?(String) ? value.to_f64(strict: false) : value.as(Float64)
            {% elsif type.id == Bool.id %}
              @{{_name.id}} = value.is_a?(JSON::Any) ? value.as_bool : ["1", "yes", "true", true].includes?(value)
            {% elsif type.id == Time.id %}
              if value.is_a?(Time)
                 @{{_name.id}} = value
               elsif value.to_s =~ TIME_FORMAT_REGEX
                 @{{_name.id}} = Time.parse(value.to_s, "%F %X")
               end
            {% else %}
              @{{_name.id}} = value.is_a?(JSON::Any) ? value.as_s : value.to_s
            {% end %}
          {% end %}
        end
      {% end %}
    rescue ex
      errors << Granite::Error.new(name, ex.message)
    end
  end
end
