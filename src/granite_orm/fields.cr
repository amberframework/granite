module Granite::ORM::Fields
  macro included
    macro inherited
      FIELDS = {} of Nil => Nil
    end
  end

  # specify the fields you want to define and types
  macro field(decl)
    {% FIELDS[decl.var] = decl.type %}
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    {% SETTINGS[:timestamps] = true %}
  end

  # define getter and setter for parent relationship
  macro belongs_to(model_name)
    field {{model_name.id}}_id : Int64
  
    # retrieve the parent relationship
    def {{model_name.id}}
      if parent = {{model_name.id.camelcase}}.find {{model_name.id}}_id
        parent
      else
        {{model_name.id.camelcase}}.new
      end
    end
  
    # set the parent relationship
    def {{model_name.id}}=(parent)
      @{{model_name.id}}_id = parent.id
    end
  end
  
  # define getter for related children
  macro has_many(children_table)
    def {{children_table.id}}
      {% children_class = children_table.id[0...-1].camelcase %}
      {% name_space = @type.name.gsub(/::/, "_").downcase.id %}
      {% table_name = SETTINGS[:table_name] || name_space + "s" %}
      foreign_key = "{{children_table.id}}.{{table_name[0...-1]}}_id"
      query = "JOIN {{table_name}} on {{table_name}}.id = #{foreign_key} WHERE {{table_name}}.id = ?"
  
      return [] of {{children_class}} unless id
      {{children_class}}.all(query, id)
    end
  end
  
  macro __process_fields
    # Create the properties
    {% for name, type in FIELDS %}
      property {{name.id}} : Union({{type.id}} | Nil)
    {% end %}
    {% if SETTINGS[:timestamps] %}
      property created_at : Time?
      property updated_at : Time?
    {% end %}

    # keep a hash of the fields to be used for mapping
    def self.fields(fields = [] of String)
      {% for name, type in FIELDS %}
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
      {% for name, type in FIELDS %}
        {% if type.id == Time.id %}
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

    # Cast params and set fields.
    private def cast_to_field(name, value : DB::Any)
      case name.to_s
        {% for _name, type in FIELDS %}
        when "{{_name.id}}"
          {% if type.id == Int32.id %}
            @{{_name.id}} = value.to_i32
          {% elsif type.id == Int64.id %}
            @{{_name.id}} = value.to_i64
          {% elsif type.id == Float32.id %}
            @{{_name.id}} = value.to_f32{0.0}
          {% elsif type.id == Float64.id %}
            @{{_name.id}} = value.to_f64{0.0}
          {% elsif type.id == Bool.id %}
            @{{_name.id}} = ["1", "yes", "true", true].includes?(value)
          {% elsif type.id == Time.id %}
            if value.is_a?(Time)
              @{{_name.id}} = value
            elsif value.to_s =~ /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/
              @{{_name.id}} = Time.parse(value, "%F %X")
            end
          {% else %}
            @{{_name.id}} = value.to_s
          {% end %}
        {% end %}
      end
    end
  end

  def set_attributes(args : Hash(Symbol | String, DB::Any))
    args.each do |k, v|
      cast_to_field(k, v)
    end
  end

  def set_attributes(**args)
    set_attributes(args.to_h)
  end
end
