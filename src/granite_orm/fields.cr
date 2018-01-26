require "json"

module Granite::ORM::Fields
  alias Type = JSON::Type | DB::Any
  TIME_FORMAT_REGEX = /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/

  macro included
    macro inherited
      FIELDS = {} of Nil => Nil
    end
  end

  # specify the fields you want to define and types
  macro field(decl, **options)
    {% FIELDS[decl.var] = options || {} of Nil => Nil %}
    {% FIELDS[decl.var][:type] = decl.type %}
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    {% SETTINGS[:timestamps] = true %}
  end

  macro __process_fields
    # Create the properties
    {% for name, options in FIELDS %}
      property {{name.id}} : Union({{options[:type].id}} | Nil)
    {% end %}
    {% if SETTINGS[:timestamps] %}
      property created_at : Time?
      property updated_at : Time?
    {% end %}

    # keep a hash of the fields to be used for mapping
    def self.fields(fields = [] of String)
      {% for name, options in FIELDS %}
        fields << "{{name.id}}"
      {% end %}
      {% if SETTINGS[:timestamps] %}
        fields << "created_at"
        fields << "updated_at"
      {% end %}
      return fields
    end

    # keep a hash of the params that will be passed to the adapter.
    def params
      parsed_params = [] of DB::Any
      {% for name, options in FIELDS %}
        {% if options[:type].id == Time.id %}
          parsed_params << {{name.id}}.try(&.to_s("%F %X"))
        {% else %}
          parsed_params << {{name.id}}
        {% end %}
      {% end %}
      {% if SETTINGS[:timestamps] %}
        parsed_params << created_at.not_nil!.to_s("%F %X")
        parsed_params << updated_at.not_nil!.to_s("%F %X")
      {% end %}
      return parsed_params
    end

    def to_h
      fields = {} of String => DB::Any

      fields["{{PRIMARY[:name]}}"] = {{PRIMARY[:name]}}

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
      {% if SETTINGS[:timestamps] %}
        fields["created_at"] = created_at.try(&.to_s("%F %X"))
        fields["updated_at"] = updated_at.try(&.to_s("%F %X"))
      {% end %}

      return fields
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "{{PRIMARY[:name]}}", {{PRIMARY[:name]}}

        {% for name, options in FIELDS %}
          {% json_options = options[:json] || {} of Nil => Nil %}
          {% type = options[:type] %}
          {% unless json_options[:hidden] %}
            %field = "{{(json_options[:as] || name).id}}"
            %value = {% if (filter = json_options[:filter]) && filter.is_a? ProcLiteral %}
                       {{filter}}.call({{name.id}})
                     {% elsif type.id == Time.id %}
                       {{name.id}}.try(&.to_s("%F %X"))
                     {% elsif type.id == Slice.id %}
                       {{name.id}}.try(&.to_s(""))
                     {% else %}
                       {{name.id}}
                     {% end %}
            json.field %field, %value
          {% end %}
        {% end %}

        {% if SETTINGS[:timestamps] %}
          json.field "created_at", created_at.try(&.to_s("%F %X"))
          json.field "updated_at", updated_at.try(&.to_s("%F %X"))
        {% end %}
      end
    end

    def set_attributes(args : Hash(String | Symbol, Type))
      args.each do |k, v|
        cast_to_field(k, v.as(Type))
      end
    end

    def set_attributes(**args)
      set_attributes(args.to_h)
    end

    # Casts params and sets fields
    private def cast_to_field(name, value : Type)
      case name.to_s
        {% for _name, options in FIELDS %}
          {% type = options[:type] %}
        when "{{_name.id}}"
          return @{{_name.id}} = nil if value.nil?
          {% if type.id == Int32.id %}
            @{{_name.id}} = value.is_a?(String) ? value.to_i32(strict: false) : value.is_a?(Int64) ? value.to_i32 : value.as(Int32)
          {% elsif type.id == Int64.id %}
            @{{_name.id}} = value.is_a?(String) ? value.to_i64(strict: false) : value.as(Int64)
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
               @{{_name.id}} = Time.parse(value.to_s, "%F %X")
             end
          {% else %}
            @{{_name.id}} = value.to_s
          {% end %}
        {% end %}
      end
    end
  end
end
