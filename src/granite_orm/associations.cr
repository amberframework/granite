module Granite::ORM::Associations
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

  macro has_many(children_table)
    def {{children_table.id}}
      {% children_class = children_table.id[0...-1].camelcase %}
      {% name_space = @type.name.gsub(/::/, "_").downcase.id %}
      {% table_name = SETTINGS[:table_name] || name_space + "s" %}
      return [] of {{children_class}} unless id
      foreign_key = "{{children_table.id}}.{{table_name[0...-1]}}_id"
      query = "WHERE #{foreign_key} = ?"
      {{children_class}}.all(query, id)
    end
  end
  
  # define getter for related children
  macro has_many(children_table, through)
    def {{children_table.id}}
      {% children_class = children_table.id[0...-1].camelcase %}
      {% name_space = @type.name.gsub(/::/, "_").downcase.id %}
      {% table_name = SETTINGS[:table_name] || name_space + "s" %}
      return [] of {{children_class}} unless id
      query = "JOIN {{through.id}} ON {{through.id}}.{{children_table.id[0...-1]}}_id = {{children_table.id}}.id "
      query = query + "WHERE {{through.id}}.{{table_name[0...-1]}}_id = ?"
      {{children_class}}.all(query, id)
    end
  end
end
