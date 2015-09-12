# A read only model provides a simple object that is returned from more
# complex queries.  This provides a way to map results of queries into a model
# without the restrictions of a full model.  The mapping is flexible and
# provides many different options.
abstract class Amethyst::Model::RoModel < Amethyst::Model::Base

  #sql_mapping maps the query to the model.  The names hash consists of the
  #name of the attribute in the model with the field in the database.  The field
  #can be any valid SQL field in SQL.  You can use calculated fields via SQL
  #functions including averages, sums, max, min or count as a SQL field.  You
  #are not limited to the fields in a table.  The table_name can also include
  #JOIN ON clauses for multiple table data sources.
  macro sql_mapping(names, table_name)

    #Set the namepace
    {% name_space = @type.name.downcase.id %}

    # Table Name
    @@table_name = "{{table_name.id}}"

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

    # fields returns a hash of the mapping between SQL and the Model.
    def self.fields
      fields = {} of String => String
      {% for name, sql in names %}
      fields["{{sql.id}}"] = "{{name.id}}"
      {% end %}
      return fields
    end
  end
  
  # all will return all the rows specified in the table.  You may include a
  # where clause and take full advantage of the database.  If you use
  # calculated fields in the sql_mapping, you will want to include any GROUP
  # BY or other clauses when calling this method.
  def self.all(clause = "", params = {} of String => String)
    self.query(@@table_name, self.fields, clause, params)
  end
end


