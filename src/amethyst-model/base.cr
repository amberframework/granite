abstract class Base
  def self.connection
    connection = nil

    yaml_file = File.read("config/database.yml")
    yaml = YAML.load(yaml_file) as Hash
    settings = yaml[Base::App.settings.environment] as Hash(YAML::Type, YAML::Type)
    
    host = settings["host"] as String
    username = settings["username"] as String
    password = settings["password"] as String
    database = settings["database"] as String
    port = settings["port"] as String
    
    connection = MySQL.connect(host, username, password, database, port.to_u16, nil)
    
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
        results = conn.query("SELECT LAST_INSERT_ID()") as Array
        id = results[0][0]
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

