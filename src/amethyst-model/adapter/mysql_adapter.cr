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

  # DDL
  def clear(table_name)
    return self.query("TRUNCATE #{table_name}")
  end

  def drop(table_name)
    return self.query("DROP TABLE IF EXISTS #{table_name}")
  end

  def create(table_name, fields)
    statement = String.build do |stmt|
      stmt << "CREATE TABLE #{table_name} ("
      stmt << "id INT NOT NULL AUTO_INCREMENT, "
      stmt << fields.map{|name, type| "#{name} #{type}"}.join(",")
      stmt << ", PRIMARY KEY (id))"
      stmt << " ENGINE=InnoDB"
      stmt << " DEFAULT CHARACTER SET = utf8"
    end
    return self.query(statement)
  end

  #DML
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
