require "./base"
require "sqlite3"

# Sqlite implementation of the Adapter
class Kemalyst::Adapter::Sqlite < Kemalyst::Adapter::Base
  @pool : ConnectionPool(SQLite3::Database)
  
  def initialize(settings)
    filename = env(settings["database"].to_s)
    @pool = ConnectionPool.new(capacity: 20) do
       SQLite3::Database.new(filename)
    end
  end

  # remove all rows from a table and reset the counter on the id.
  def clear(table_name)
    self.query("DELETE FROM #{table_name}")
  end

  # drop the table
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

  def migrate(table_name, fields)
    raise "Not Available for Sqlite"
  end

  def prune(table_name, fields)
    raise "Not Available for Sqlite"
  end

  def add_field(table_name, name, type, previous = nil)
    raise "Not Available for Sqlite"
  end
  
  def rename_field(table_name, from, to, type)
    raise "Not Available for Sqlite"
  end

  def remove_field(table_name, name)
    raise "Not Available for Sqlite"
  end

  # Copy data from one column to another
  def copy_field(table_name, from, to)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name}"
      stmt << " SET #{to} = #{from}"
    end
    return self.query(statement)
  end
  
  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  def select(table_name, fields, clause = "", params = {} of String => String)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << " FROM #{table_name} #{clause}"
    end
    return self.query(statement, params, fields)
  end
  
  # select_one is used by the find method.
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
    id = nil
    self.query(statement, params)
    results = self.query("SELECT LAST_INSERT_ROWID()") as Array
    id = results[0][0] as Int64
    return id
  end
  
  # This will update a row in the database.
  def update(table_name, fields, id, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name} SET "
      stmt << fields.map{|name, type| "#{name}=:#{name}"}.join(",")
      stmt << " WHERE id=:id"
    end
    if id
      params["id"] = "#{id}"
    end
    return self.query(statement, params, fields)
  end
  
  # This will delete a row from the database.
  def delete(table_name, id)
    return self.query("DELETE FROM #{table_name} WHERE id=:id", {"id" => id})
  end

  def query(statement : String, params = {} of String => String, fields = {} of Symbol => String)
    conn = @pool.connection
    if conn
      begin
        results = conn.execute(statement, scrub_params(params))
      ensure
        @pool.release
      end
    end
    return results
  end

  alias SUPPORTED_TYPES = (Float64 | Int64 | Slice(UInt8) | String | Nil)

  private def scrub_params(params)
    new_params = {} of String => SUPPORTED_TYPES
    params.each do |key, value|
      if value.is_a? SUPPORTED_TYPES
        if value.is_a? Time
          new_params[key] = db_time(value)
        else
          new_params[key] = value
        end
      end
    end
    return new_params
  end

  private def db_time (time)
    formatter = Time::Format.new("%F %X")
    return formatter.format(time)
  end

end


