module Granite::Associations
  macro belongs_to(model)
    {% if model.is_a? TypeDeclaration %}
      belongs_to {{model.var}}, {{model.type}}, {{model.var}}_id : Int64
    {% else %}
      belongs_to {{model.id}}, {{model.id.camelcase}}, {{model.id}}_id : Int64
    {% end %}
  end

  macro belongs_to(model, foreign_key)
    {% if model.is_a? TypeDeclaration %}
      belongs_to {{model.var}}, {{model.type}}, {{foreign_key}}
    {% else %}
      belongs_to {{model.id}}, {{model.id.camelcase}}, {{foreign_key}}
    {% end %}
  end

  macro belongs_to(model, class_name, foreign_key)
    field {{foreign_key}}

    def {{model.id}}
      if parent = {{class_name.id}}.find {{foreign_key.var}}
        parent
      else
        {{class_name.id}}.new
      end
    end

    def {{model.id}}=(parent)
      @{{foreign_key.var}} = parent.id
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
    def {{method_name}}
      {{class_name.id}}.find_by({{foreign_key.id}}: self.id)
    end

    def {{method_name}}=(children)
      children.{{foreign_key.id}} = self.id
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
