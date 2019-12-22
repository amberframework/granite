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

    {% foreign_key = (options[:foreign_key] || @type.stringify.split("::").last.underscore + "_id").id %}
    {% primary_key = (options[:primary_key] || "id").id %}

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    @{{name}} : {{type}}?

    def {{nilable_method}} : {{type}}?
      @{{name}} ||= {{type}}.find_by({{foreign_key}}: self.{{primary_key}})
    end

    def {{not_nil_method}} : {{type}}
      @{{name}} ||= {{type}}.find_by!({{foreign_key}}: self.{{primary_key}})
    end

    def {{name}}=(child : {{type}}) : {{type}}
      child.{{foreign_key.id}} = self.{{primary_key.id}}
      @{{name}} = child
    end

    def reload_{{name}} : {{type}}?
      @{{name}} = nil
      {{nilable_method}}
    end
  end

  macro has_many(model, **options)
    {%
      if model.is_a? TypeDeclaration
        name = model.var.id
        type = model.type
      else
        name = model.id
        type = options[:class_name] || model.id.camelcase
      end
    %}
    {%
      type = type.id
      foreign_key = (options[:foreign_key] || @type.stringify.split("::").last.underscore + "_id").id
      through = options[:through] && options[:through].id.stringify
    %}

    @{{name}} : Granite::AssociationCollection(self, {{type}})?

    def {{name}} : Granite::AssociationCollection(self, {{type}})
      @{{name}} ||= Granite::AssociationCollection(self, {{type}}).new(self, "{{foreign_key}}", {{through}})
    end

    def reload_{{name}} : Granite::AssociationCollection(self, {{type}})
      @{{name}} = nil
      {{name}}
    end
  end
end
