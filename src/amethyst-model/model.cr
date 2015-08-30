require "yaml"
require "mysql"

abstract class Model < Base

  def initialize
  end

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

    # Create OR Mapping
    def self.or_mapping(result)
      {{@type.name.downcase.id}} = {{@type.name.id}}.new
      {{@type.name.downcase.id}}.id = result[0] 
      {% i = 1 %}
      {% for name, type in names %}
        {{@type.name.downcase.id}}.{{name.id}} = result[{{i}}]
        {% i += 1 %}
      {% end %}

      {% if timestamps %}
        {{@type.name.downcase.id}}.created_at = result[{{i}}]
        {{@type.name.downcase.id}}.updated_at = result[{{i + 1}}]
      {% end %}
      return {{@type.name.downcase.id}}
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
                        , PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8")
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

