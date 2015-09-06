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
      if db = @@database
        db.clear("{{table_name.id}}")
      end
    end

    def self.drop
      if db = @@database
        db.drop("{{table_name.id}}")
      end
    end

    def self.create
      if db = @@database
        fields = {} of String => String
        {% for name, type in names %}
        fields["{{name.id}}"] = "{{type.id}}"
        {% end %}
        {% if timestamps %}
        fields["created_at"] = "DATETIME"
        fields["updated_at"] = "DATETIME"
        {% end %}
        db.create("{{table_name.id}}", fields)
      end
    end

    # DML
    def self.all(clause = "", params = {} of String => String)
      statement = String.build do |stmt|
        stmt << "SELECT {{name_space}}.id"
        {% for name, type in names %}
          stmt << ", {{name_space}}.{{name.id}}"
        {% end %}
        {% if timestamps %}
          stmt << ", {{name_space}}.created_at, {{name_space}}.updated_at"
        {% end %}
        stmt << " FROM {{table_name.id}} {{name_space}} #{clause}"
      end
      return self.query(statement, params)
    end
    
    def self.find(id)
      statement = String.build do |stmt|
        stmt << "SELECT id"
        {% for name, type in names %}
          stmt << ", {{name.id}}"
        {% end %}
        {% if timestamps %}
          stmt << ", created_at, updated_at"
        {% end %}
        stmt << " FROM {{table_name.id}}"
        stmt << " WHERE id = :id LIMIT 1"
      end
      return self.query_one(statement, {"id" => id})
    end
    
    def save
      if id
        updated_at = Time.now
        statement = String.build do |stmt|
          stmt << "UPDATE {{table_name.id}} SET "
          {% first = true %}
          {% for name, type in names %}
            {% unless first %}stmt << ", "{% end %}
            stmt << "{{name.id}}={{name}}"
            {% first = false %}
          {% end %}
          {% if timestamps %}
            stmt << ", updated_at=:updated_at"
          {% end %}
          stmt << " WHERE id=:id"
        end
        update(statement, {
          {% first = true %}
          {% for name, type in names %}
            {% unless first %}, {% end %}
            "{{name.id}}" => {{name.id}}
            {% first = false %}
          {% end %}
          {% if timestamps %}
            , "updated_at" => db_time(updated_at),
          {% end %}
          "id" => id})
      else
        created_at = Time.now
        updated_at = Time.now
        statement = String.build do |stmt|
          stmt << "INSERT INTO {{table_name.id}} ("
          {% first = true %}
          {% for name, type in names %}
            {% unless first %}stmt << ", "{% end %}
            stmt << "{{name.id}}"
            {% first = false %}
          {% end %}
          {% if timestamps %}
            stmt << ", created_at, updated_at"
          {% end %}
          stmt << ") VALUES ("
          {% first = true %}
          {% for name, type in names %}
            {% unless first %}stmt << ", "{% end %}
            stmt << "{{name}}"
            {% first = false %}
          {% end %}
          {% if timestamps %}
            stmt << ", :created_at, :updated_at"
          {% end %}
          stmt << ")"
        end

        @id = insert(statement, {
          {% first = true %}
          {% for name, type in names %}
            {% unless first %}, {% end %}
            "{{name.id}}" => {{name.id}}
            {% first = false %}
          {% end %}
          {% if timestamps %}
            , "created_at" => db_time(created_at)
            , "updated_at" => db_time(updated_at)
          {% end %}})
      end
      return true
    end

    def destroy
      return update("DELETE FROM {{table_name.id}} WHERE id=:id", {"id" => id})
    end
     
  end #End of Fields Macro

  private def db_time (time)
    formatter = TimeFormat.new("%F %X")
    return formatter.format(time)
  end
end

