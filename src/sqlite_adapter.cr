require "./amethyst-model"
require "sqlite3"

class Amethyst::Model::SqliteAdapter < Amethyst::Model::BaseAdapter

  def initialize(settings)
    @database = settings["database"] as String
  end

  # DDL
  def clear(table_name)
    self.query("DELETE FROM #{table_name}")
  end

  def drop(table_name)
    return self.query("DROP TABLE IF EXISTS #{table_name}")
  end

  def create(table_name, fields)
    statement = String.build do |stmt|
      stmt << "CREATE TABLE #{table_name} ("
      stmt << "id INTEGER NOT NULL PRIMARY KEY, "
      stmt << fields.map{|name, type| "#{name} #{type}"}.join(",")
      stmt << ")"
    end
    return self.query(statement)
  end

  def select(table_name, fields, clause = "", params = {} of String => String)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << " FROM #{table_name} #{clause}"
    end
    return self.query(statement, params)
  end
  
  def select_one(table_name, fields, id)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << " FROM #{table_name}"
      stmt << " WHERE id=:id LIMIT 1"
    end
    return self.query(statement, {"id" => id})
  end

  def insert(table_name, fields, params)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{table_name} ("
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << ") VALUES ("
      stmt << fields.map{|name, type| ":#{name}"}.join(",")
      stmt << ")"
    end
    conn = SQLite3::Database.new( @database )
    if conn
      begin
        conn.execute(statement, scrub_params(params))
        results = conn.execute("SELECT LAST_INSERT_ROWID()") as Array
        id = results[0][0]
      ensure
        conn.close
      end
    end
    return id

  end
  
  def update(table_name, fields, id, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name} SET "
      stmt << fields.map{|name, type| "#{name}=:#{name}"}.join(",")
      stmt << " WHERE id=:id"
    end
    if id
      params["id"] = "#{id}"
    end
    return self.query(statement, params)
  end
  
  def delete(table_name, id)
    return self.query("DELETE FROM #{table_name} WHERE id=:id", {"id" => id})
  end

  def query(query, params = {} of String => String)
    conn = SQLite3::Database.new( @database )
    if conn
      begin
        results = conn.execute(query, scrub_params(params))
      ensure
        conn.close
      end
    end
    return results
  end

  alias SUPPORTED_TYPES = (Nil | String | Int32 | Int16 | Int64 | Float32 |
                           Float64 | Bool | Time | Char | Slice(UInt8))
  private def scrub_params(params)
    new_params = {} of String => SUPPORTED_TYPES
    params.each do |key, value|
      if value.is_a? Time
        new_params[key] = db_time(value)
      else
        new_params[key] = value
      end
    end
    return new_params
  end

  private def db_time (time)
    if time.is_a? Time
      formatter = TimeFormat.new("%F %X")
      return formatter.format(time)
    end
    return time
  end

end

