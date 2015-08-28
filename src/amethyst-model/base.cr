abstract class Base
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
    conn = Base.connection
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
    conn = Base.connection
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
end

