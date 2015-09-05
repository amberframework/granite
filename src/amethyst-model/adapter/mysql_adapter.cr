require "mysql"

class Amethyst::Model::MysqlAdapter < Amethyst::Model::BaseAdapter

  def initialize(settings)
    @host = settings["host"] as String
    @host = env(@host) if @host.starts_with? "$"

    @port = settings["port"] as String
    @port = env(@port) if @port.starts_with? "$"
    
    @username = settings["username"] as String
    @username = env(@username) if @username.starts_with? "$"
    
    @password = settings["password"] as String
    @password = env(@password) if @password.starts_with? "$"
    
    @database = settings["database"] as String
    @database = env(@database) if @database.starts_with? "$"
  end

  def query(query, params = {} of String => String)
    conn = MySQL.connect(@host, @username, @password, @database, @port.to_u16, nil)
    if conn
      begin
        results = MySQL::Query.new(query, params).run(conn)
      ensure
        conn.close
      end
    end
    return results
  end
  
  def insert(query, params = {} of String => String)
    conn = MySQL.connect(@host, @username, @password, @database, @port.to_u16, nil)
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
    conn = MySQL.connect(@host, @username, @password, @database, @port.to_u16, nil)
    if conn
      begin
        MySQL::Query.new(query, params).run(conn)
      ensure
        conn.close
      end
    end
    return true
  end

end
