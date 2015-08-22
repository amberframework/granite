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

    macro fields(names)
      property :id, :created_at, :updated_at
      {% for name, type in names %}
        property {{name}}
      {% end %}

      def self.mapping(result)
        {{@type.name.downcase.id}} = {{@type.name.id}}.new
        {{@type.name.downcase.id}}.id = result[0] 
        {% i = 1 %}
        {% for name, type in names %}
          {{@type.name.downcase.id}}.{{name.id}} = result[{{i}}]
          {% i += 1 %}
        {% end %}
        {{@type.name.downcase.id}}.created_at = result[{{i}}]
        {{@type.name.downcase.id}}.updated_at = result[{{i + 1}}]
        return post
      end

      # DDL
      def self.clear
        return self.query("TRUNCATE {{@type.name.downcase.id}}s")
      end

      def self.create
        return self.query("CREATE TABLE {{@type.name.downcase.id}}s (
                          id INT NOT NULL AUTO_INCREMENT,
                          {% for name, type in names %}
                            {{name.id}} {{type.id}}, 
                          {% end %}            
                          created_at DATE,
                          updated_at DATE 
                          PRIMARY KEY (id))")
      end

      def self.drop
        return self.query("DROP table {{@type.name.downcase.id}}s")
      end

      # DML
      def self.all(clause = "", params = {} of String => String)
        return self.query("SELECT _t.id, 
                           {% for name, type in names %}
                             _t.{{name.id}}, 
                           {% end %}            
                           _t.created_at, _t.updated_at 
                           FROM {{@type.name.downcase.id}}s _t 
                           #{clause}", params)
      end
      
      def self.find(id)
        return self.query_one("SELECT id, 
                               {% for name, type in names %}
                                 {{name.id}}, 
                               {% end %}            
                               created_at, updated_at
                               FROM {{@type.name.downcase.id}}s 
                               WHERE id = :id 
                               LIMIT 1", {"id" => id})
      end
      
      def save
        if id
          updated_at = Time.now
          update("UPDATE {{@type.name.downcase.id}}s SET 
                  {% for name, type in names %}
                    {{name.id}}={{name}}, 
                  {% end %}
                  updated_at=:updated_at 
                  WHERE id=:id", {
                  {% for name, type in names %}
                    "{{name.id}}" => {{name.id}}, 
                  {% end %}
                  "updated_at" => updated_at, 
                  "id" => id})
        else
          created_at = Time.now
          updated_at = Time.now
          @id = insert("INSERT INTO {{@type.name.downcase.id}}s (
                        {% for name, type in names %}
                          {{name.id}}, 
                        {% end %}
                        created_at, 
                        updated_at)
                        VALUES (
                        {% for name, type in names %}
                          {{name}}, 
                        {% end %}
                        :created_at, :updated_at)", {
                        {% for name, type in names %}
                          "{{name.id}}" => {{name.id}}, 
                        {% end %}
                        "created_at" => created_at, 
                        "updated_at" => updated_at})
        end
        return true
      end

      def destroy
        return update("DELETE FROM {{@type.name.downcase.id}}s 
                      WHERE id=:id", {"id" => id})
      end
       
    end #End of Fields Macro

    macro has_many(name)

    end

    macro belongs_to(name)

    end
    
  end

  
end

