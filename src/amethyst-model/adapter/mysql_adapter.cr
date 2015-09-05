require "mysql"

class MySQLAdapter < BaseAdapter

  def initialize(@host, @username, @password, @database, @port)
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
