module Granite::ORM::Associations
  # define getter and setter for parent relationship
  macro belongs_to(model_name)
    belongs_to {{model_name}}, {{model_name.id}}_id : Int64
  end

  macro belongs_to(model_name, decl)
    field {{decl.var}} : {{decl.type}}

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
