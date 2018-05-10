module Granite::ORM::Associations
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

  macro has_many(children_table)
    def {{children_table.id}}
      {% children_class = children_table.id[0...-1].camelcase %}
      Granite::ORM::AssociationCollection(self, {{children_class}}).new(self)
    end
  end

  # define getter for related children
  macro has_many(children_table, through)
    def {{children_table.id}}
      {% children_class = children_table.id[0...-1].camelcase %}
      Granite::ORM::AssociationCollection(self, {{children_class}}).new(self, {{through}})
    end
  end
end
