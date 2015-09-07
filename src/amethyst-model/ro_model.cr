abstract class Amethyst::Model::RoModel < Amethyst::Model::Base

  macro sql_mapping(names, table_name)

    #Set the namepace
    {% name_space = @type.name.downcase.id %}

    {% for name, type in names %}
      property {{name}}
    {% end %}

    # Create the or mapping method
    def self.from_sql(result)
      {{name_space}} = {{@type.name.id}}.new
      {% i = 0 %}
      {% for name, type in names %}
        {{name_space}}.{{name.id}} = result[{{i}}]
        {% i += 1 %}
      {% end %}

      return {{name_space}}
    end

    def self.fields
      fields = {} of String => String
      {% for name, sql in names %}
      fields["{{sql.id}}"] = "{{name.id}}"
      {% end %}
      return fields
    end

    def self.all(clause = "", params = {} of String => String)
      self.query("{{table_name.id}}", self.fields, clause, params)
    end

  end #End of Fields Macro
end


