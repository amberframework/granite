module Granite::Associations
  macro belongs_to(model, **options)
    {% if model.is_a? TypeDeclaration %}
      {% method_name = model.var %}
      {% class_name = model.type %}
    {% else %}
      {% method_name = model.id %}
      {% class_name = options[:class_name] || model.id.camelcase %}
    {% end %}

    {% if options[:foreign_key] && options[:foreign_key].is_a? TypeDeclaration %}
      {% foreign_key = options[:foreign_key].var %}
      field {{options[:foreign_key]}}, json_options: {{options[:json_options]}}, yaml_options: {{options[:yaml_options]}}
    {% else %}
      {% foreign_key = method_name + "_id" %}
      field {{foreign_key}} : Int64?, json_options: {{options[:json_options]}}, yaml_options: {{options[:yaml_options]}}
    {% end %}

    def {{method_name.id}} : {{class_name.id}}
      if parent = {{class_name.id}}.find {{foreign_key}}
        parent
      else
        {{class_name.id}}.new
      end
    end

    def {{method_name.id}}=(parent : {{class_name.id}})
      @{{foreign_key}} = parent.id!
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
      children.{{foreign_key.id}} = self.id!
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
