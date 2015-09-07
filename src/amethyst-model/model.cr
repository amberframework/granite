abstract class Amethyst::Model::Model < Amethyst::Model::Base

  macro sql_mapping(names, table_name = nil, timestamps = true)
    {% name_space = @type.name.downcase.id %}
    {% table_name = name_space + "s" unless table_name %}
    # Table Name
    @@table_name = "{{table_name}}"
    #Create the properties
    property :id
    {% for name, type in names %}
    property {{name}}
    {% end %}
    {% if timestamps %}
    property :created_at, :updated_at
    {% end %}
    
    # Create the from_sql method
    def self.from_sql(result)
      {{name_space}} = {{@type.name.id}}.new
      {{name_space}}.id = result[0] 
      {% i = 1 %}
      {% for name, type in names %}
        {{name_space}}.{{name.id}} = result[{{i}}]
        {% i += 1 %}
      {% end %}

      {% if timestamps %}
        {{name_space}}.created_at = result[{{i}}]
        {{name_space}}.updated_at = result[{{i + 1}}]
      {% end %}
      return {{name_space}}
    end

    def self.fields(fields = {} of String => String)
        {% for name, type in names %}
        fields["{{name.id}}"] = "{{type.id}}"
        {% end %}
        {% if timestamps %}
        fields["created_at"] = "TIMESTAMP"
        fields["updated_at"] = "TIMESTAMP"
        {% end %}
        return fields
    end

    def params
      return {
          {% first = true %}
          {% for name, type in names %}
            {% unless first %}, {% end %}
            "{{name.id}}" => {{name.id}}
            {% first = false %}
          {% end %}
          {% if timestamps %}
            , "created_at" => created_at
            , "updated_at" => updated_at
          {% end %}
      }
    end

    # TODO: because these are instance methods, it causes issues when specified
    # outside of the macro.  Find a way to restrict the types because the
    # drivers are polluting the inferred types.
    def save
      if db = @@database
        if value = @id
          updated_at = Time.now
          db.update(@@table_name, self.class.fields, value, params)
        else
          @created_at = Time.now
          @updated_at = Time.now
          @id = db.insert(@@table_name, self.class.fields, params)
        end
      end
      return true
    end

    def destroy
      if db = @@database
        return db.delete(@@table_name, @id)
      end
    end
  end #End of Fields Macro

  # DDL
  def self.clear
    if db = @@database
      db.clear(@@table_name)
    end
  end

  def self.drop
    if db = @@database
      db.drop(@@table_name)
    end
  end

  def self.create
    if db = @@database
      db.create(@@table_name, fields)
    end
  end

  def self.all(clause = "", params = {} of String => String)
    return self.query(@@table_name, fields({"id" => "INT"}), clause, params)
  end
  
  def self.find(id)
    return self.query_one(@@table_name, fields({"id" => "INT"}), id)
  end
  

end

