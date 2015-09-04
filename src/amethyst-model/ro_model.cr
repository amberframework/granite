require "yaml"
require "mysql"

abstract class RoModel < Base

  macro fields(names, table_name)

    #Set the namepace
    {% name_space = @type.name.downcase.id %}

    {% for name, type in names %}
      property {{name}}
    {% end %}

    # Create the or mapping method
    def self.or_mapping(result)
      {{name_space}} = {{@type.name.id}}.new
      {% i = 0 %}
      {% for name, type in names %}
        {{name_space}}.{{name.id}} = result[{{i}}]
        {% i += 1 %}
      {% end %}

      return {{name_space}}
    end

    # DML
    def self.all(clause = "", params = {} of String => String)
      return self.query("SELECT 
                         {% first = true %}
                         {% for name, sql in names %}
                           {% unless first %}, {% end %}
                             {{sql.id}}
                           {% first = false %}
                         {% end %}
                         FROM {{table_name.id}} {{name_space}} 
                         #{clause}", params)
    end
    
  end #End of Fields Macro
end


