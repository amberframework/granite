abstract class Amethyst::Model::Model < Amethyst::Model::Base

  macro fields(names, table_name = nil, timestamps = true)

    #Set the namepace
    {% name_space = @type.name.downcase.id %}

    #Set the table name
    {% table_name = name_space + "s" unless table_name %}


    #Create the properties
    property :id
      
    {% for name, type in names %}
      property {{name}}
    {% end %}

    {% if timestamps %}
      property :created_at, :updated_at
    {% end %}

    # Create the or mapping method
    def self.or_mapping(result)
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

    # DDL
    def self.clear
      return self.query("TRUNCATE {{table_name.id}}")
    end

    def self.create
      return self.query("CREATE TABLE {{table_name.id}} (
                        id INT NOT NULL AUTO_INCREMENT
                        {% for name, type in names %}
                          , {{name.id}} {{type.id}} 
                        {% end %}
                        {% if timestamps %}
                          , created_at DATE, updated_at DATE 
                        {% end %}
                        , PRIMARY KEY (id))")
    end

    def self.drop
      return self.query("DROP TABLE IF EXISTS {{table_name.id}}")
    end

    # DML
    def self.all(clause = "", params = {} of String => String)
      return self.query("SELECT {{name_space}}.id 
                         {% for name, type in names %}
                           , {{name_space}}.{{name.id}} 
                         {% end %}
                         {% if timestamps %}
                           , {{name_space}}.created_at, {{name_space}}.updated_at
                         {% end %}
                         FROM {{table_name.id}} {{name_space}} 
                         #{clause}", params)
    end
    
    def self.find(id)
      return self.query_one("SELECT id 
                             {% for name, type in names %}
                               , {{name.id}} 
                             {% end %}
                             {% if timestamps %}
                               , created_at, updated_at
                             {% end %}
                             FROM {{table_name.id}} 
                             WHERE id = :id 
                             LIMIT 1", {"id" => id})
    end
    
    def save
      if id
        updated_at = Time.now
        update("UPDATE {{table_name.id}} SET 
                {% first = true %}
                {% for name, type in names %}
                  {% unless first %}, {% end %}
                  {{name.id}}={{name}} 
                  {% first = false %}
                {% end %}
                {% if timestamps %}
                  , updated_at=:updated_at 
                {% end %}
                WHERE id=:id", {
                {% first = true %}
                {% for name, type in names %}
                  {% unless first %}, {% end %}
                  "{{name.id}}" => {{name.id}}
                  {% first = false %}
                {% end %}
                {% if timestamps %}
                  , "updated_at" => updated_at, 
                {% end %}
                "id" => id})
      else
        created_at = Time.now
        updated_at = Time.now
        @id = insert("INSERT INTO {{table_name.id}} (
                      {% first = true %}
                      {% for name, type in names %}
                        {% unless first %}, {% end %}
                        {{name.id}}
                        {% first = false %}
                      {% end %}
                      {% if timestamps %}
                        , created_at, updated_at
                      {% end %})
                      VALUES (
                      {% first = true %}
                      {% for name, type in names %}
                        {% unless first %}, {% end %}
                        {{name}} 
                        {% first = false %}
                      {% end %}
                      {% if timestamps %}
                        , :created_at, :updated_at
                      {% end %})", {
                      {% first = true %}
                      {% for name, type in names %}
                        {% unless first %}, {% end %}
                        "{{name.id}}" => {{name.id}}
                        {% first = false %}
                      {% end %}
                      {% if timestamps %}
                        , "created_at" => created_at, "updated_at" => updated_at
                      {% end %}})
      end
      return true
    end

    def destroy
      return update("DELETE FROM {{table_name.id}} 
                     WHERE id=:id", {"id" => id})
    end
     
  end #End of Fields Macro
end

