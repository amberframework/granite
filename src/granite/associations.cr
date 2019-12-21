module Granite::Associations
  macro belongs_to(model, **options)
    {%
      nilable = false
      if model.is_a? TypeDeclaration
        name = model.var.id
        type = model.type
      else
        name = model.id
        type = options[:class_name] || name.camelcase
      end
      if type.is_a? Union
        nilable = type.types.any?(&.resolve?.== Nil)
        type = type.types.find(&.resolve?.!= Nil)
      end
      if nilable
        nilable_method = name
        not_nil_method = name + "!"
      else
        nilable_method = name + "?"
        not_nil_method = name
      end
      type = type.id
    %}

    {% if options[:foreign_key] && options[:foreign_key].is_a? TypeDeclaration %}
      {% foreign_key = options[:foreign_key].var.id %}
      column {{options[:foreign_key]}}
    {% else %}
      {% foreign_key = name + "_id" %}
      column {{foreign_key}} : Int64?
    {% end %}
    {% primary_key = (options[:primary_key] || "id").id %}

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    @{{name}} : {{type}}?

    def {{nilable_method}} : {{type}}?
      @{{name}} ||= {{type}}.find_by({{primary_key}}: {{foreign_key}})
    end

    def {{not_nil_method}} : {{type}}
      @{{name}} ||= {{type}}.find_by!({{primary_key}}: {{foreign_key}})
    end

    def {{name}}=(parent : {{type}}) : {{type}}
      @{{foreign_key}} = parent.{{primary_key}}
      @{{name}} = parent
    end

    def reload_{{name}} : {{type}}?
      @{{name}} = nil
      {{nilable_method}}
    end
  end

  macro has_one(model, **options)
    {% if model.is_a? TypeDeclaration %}
      {% method_name = model.var %}
      {% class_name = model.type %}
    {% else %}
      {% method_name = model.id %}
      {% class_name = options[:class_name] || model.id.camelcase %}
    {% end %}
    {% foreign_key = options[:foreign_key] || @type.stringify.split("::").last.underscore + "_id" %}
    {% primary_key = options[:primary_key] || "id" %}

    def {{method_name}} : {{class_name}}?
      {{class_name.id}}.find_by({{foreign_key.id}}: self.{{primary_key.id}})
    end

    def {{method_name}}! : {{class_name}}
      {{class_name.id}}.find_by!({{foreign_key.id}}: self.{{primary_key.id}})
    end

    def {{method_name}}=(child)
      child.{{foreign_key.id}} = self.{{primary_key.id}}
    end
  end

  macro has_many(model, **options)
    {% if model.is_a? TypeDeclaration %}
      {% method_name = model.var %}
      {% class_name = model.type %}
    {% else %}
      {% method_name = model.id %}
      {% class_name = options[:class_name] || model.id.camelcase %}
    {% end %}
    {% foreign_key = options[:foreign_key] || @type.stringify.split("::").last.underscore + "_id" %}
    {% through = options[:through] %}
    def {{method_name.id}}
      Granite::AssociationCollection(self, {{class_name.id}}).new(self, {{foreign_key}}, {{through}})
    end
  end
end
