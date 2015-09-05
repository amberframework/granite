require "sqlite3"

class Amethyst::Model::SqliteAdapter < Amethyst::Model::BaseAdapter

  def initialize(settings)
    @database = settings["database"] as String
    @database = env(@database) if @database.starts_with? "$"
  end

  # DDL
  def clear(table_name)
    self.query("DELETE FROM #{table_name}")
  end

  def drop(table_name)
    return self.query("DROP TABLE IF EXISTS #{table_name}")
  end

  def create(table_name, fields)
    value = "CREATE TABLE #{table_name}"
    value = value + "(id INTEGER PRIMARY KEY NOT NULL"
    fields.each do |name, type|
      value = value + ", #{name} #{type}" 
    end
    value = value + ")"
    return self.query(value)
  end

  # DML
  def query(query, params = {} of String => String)
    conn = SQLite3::Database.new( @database )
    if conn
      begin
        results = conn.execute(query, params)
      ensure
        conn.close
      end
    end
    return results
  end
  
  def insert(query, params = {} of String => String)
    conn = SQLite3::Database.new( @database )
    if conn
      begin
        conn.execute(query, params)
        results = conn.execute("SELECT LAST_INSERT_ROWID()") as Array
        id = results[0][0]
      ensure
        conn.close
      end
    end
    return id
  end
  
  def update(query, params = {} of String => String)
    conn = SQLite3::Database.new( @database )
    if conn
      begin
        conn.execute(query, params)
      ensure
        conn.close
      end
    end
    return true
  end

end

