require "yaml"
require "mysql"

module Base
  abstract class Model

    def self.connection
      connection = nil

      yaml_file = File.read("config/database.yml")
      yaml = YAML.load(yaml_file)
      if yaml.is_a?(Hash(YAML::Type, YAML::Type))
        settings = yaml[Base::App.settings.environment]
        if settings.is_a?(Hash(YAML::Type, YAML::Type))
          if settings["host"]
            host = settings["host"]
          end
          if settings["username"]
            username = settings["username"]
          end
          if settings["password"]
            password = settings["password"]
          end
          if settings["database"]
            database = settings["database"]
          end
          if settings["port"]
            port = settings["port"]
            if port.is_a?(String)
              port = port.to_u16
            end
          end
        end
      end
      
      if host.is_a?(String) &&
         username.is_a?(String) && 
         password.is_a?(String) &&
         database.is_a?(String) &&
         port.is_a?(UInt16)
          connection = MySQL.connect(host, username, password, database, port, nil)
      end
      
      return connection
    end

    def self.query(query, params = {} of String => String)
      rows = [] of self
      conn = self.connection
      if conn
        begin
          results = MySQL::Query.new(query, params).run(conn)
          if results.is_a?(Array)
            if results.size > 0
              results.each do |result|
                rows << mapping(result)
              end
            end
          end
        ensure
          conn.close
        end
      end
      return rows
    end

    def self.query_one(query, params = {} of String => String)
      row = nil
      rows = self.query(query, params)
      if rows && rows.size > 0
        row = rows[0]
      end
      return row
    end

    def insert(query, params = {} of String => String)
      conn = Base::Model.connection
      if conn
        begin
          MySQL::Query.new(query, params).run(conn)
          results = conn.query("SELECT LAST_INSERT_ID()")
                                 
          if results
            id = results[0][0]
          end
        ensure
          conn.close
        end
      end
      return id
    end

    def update(query, params = {} of String => String)
      conn = Base::Model.connection
      if conn
        begin
          MySQL::Query.new(query, params).run(conn)
        ensure
          conn.close
        end
      end
      return true
    end

    abstract def mapping(results : Array)

    macro fields(names, table_name = nil, timestamps = true)

      #Set the table name
      {% table_name = @type.name.downcase.id + "s" unless table_name %}

      #Create the properties
      property :id
        
      {% for name, type in names %}
        property {{name}}
      {% end %}

      {% if timestamps %}
        property :created_at, :updated_at
      {% end %}

      # Create the mapping method
      def self.mapping(result)
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
                          , PRIMARY KEY (id))")
      end

      def self.drop
        return self.query("DROP table {{table_name.id}}")
      end

      # DML
      def self.all(clause = "", params = {} of String => String)
        return self.query("SELECT _t.id 
                           {% for name, type in names %}
                             , _t.{{name.id}} 
                           {% end %}
                           {% if timestamps %}
                             , _t.created_at, _t.updated_at
                           {% end %}
                           FROM {{table_name.id}} _t 
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
end


