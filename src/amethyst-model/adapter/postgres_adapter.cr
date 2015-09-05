require "pg"

class Amethyst::Model::PostgresAdapter < Amethyst::Model::BaseAdapter

  def initialize(settings)
    @connection = settings["connection"] as String
    @connection = env(@connection) if @connection.starts_with? "$"
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
    conn = PG.connect(@connection)
    if conn
      begin
        results = conn.exec(query, params)
        return results.rows
      ensure
        conn.close
      end
    end
    return [] of String
  end

  def insert(query, params = {} of String => String)
    conn = PG.connect(@connection)
    if conn
      begin
        conn.exec(query, params)
        results = conn.exec("SELECT LAST_INSERT_ID()") as Array
        id = results.rows[0][0]
      ensure
        conn.close
      end
    end
    return id
  end

  def update(query, params = {} of String => String)
    conn = PG.connect(@connection)
    if conn
      begin
        conn.exec(query, params)
      ensure
        conn.close
      end
    end
    return true
  end

end

