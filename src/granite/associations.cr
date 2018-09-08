module Granite::Associations
  # define getter and setter for parent relationship
  macro belongs_to(model)
    {% if model.is_a? TypeDeclaration %}
      belongs_to {{model.var}}, {{model.type}}, {{model.var}}_id : Int64
    {% else %}
      belongs_to {{model.id}}, {{model.id.camelcase}}, {{model.id}}_id : Int64
    {% end %}
  end

  # ditto
  macro belongs_to(model, foreign_key)
    {% if model.is_a? TypeDeclaration %}
      belongs_to {{model.var}}, {{model.type}}, {{foreign_key}}
    {% else %}
      belongs_to {{model.id}}, {{model.id.camelcase}}, {{foreign_key}}
    {% end %}
  end

  # ditto
  macro belongs_to(method_name, model_name, foreign_key)
    field {{foreign_key}}

    # retrieve the parent relationship
    def {{method_name.id}}
      if parent = {{model_name.id}}.find {{foreign_key.var}}
        parent
      else
        {{model_name.id}}.new
      end
    end

    # set the parent relationship
    def {{method_name.id}}=(parent)
      @{{foreign_key.var}} = parent.id
    end
  end

  macro has_one(model_name)
    {% foreign_key = @type.stringify.split("::").last.underscore + "_id" %}
    has_one {{model_name.id}}, {{foreign_key.id}}
  end

  macro has_one(model_name, foreign_key)
    def {{model_name.id}}
      {{model_name.id.camelcase}}.find_by({{foreign_key.id}}: self.id)
    end

    def {{model_name.id}}=(children)
      children.{{foreign_key.id}} = self.id
    end
  end

  macro has_many(model)
    def {{model.id}}
      Granite::AssociationCollection(self, {{model.id.camelcase}}).new(self)
    end
  end

  macro has_many(model, model_name)
    def {{model.id}}
      Granite::AssociationCollection(self, {{model_name.id}}).new(self)
    end
  end

  macro has_many(model, model_name, through)
    def {{model.id}}
      Granite::AssociationCollection(self, {{model_name.id}}).new(self, {{through}})
    end
  end
end
