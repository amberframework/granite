require "./base"
require "sqlite3"

# Sqlite implementation of the Adapter
class Kemalyst::Adapter::Sqlite < Kemalyst::Adapter::Base
  # remove all rows from a table and reset the counter on the id.
  def clear(table_name)
    open do |db|
      db.exec "DELETE FROM #{table_name}"
    end
  end

  # drop the table
  def drop(table_name)
    open do |db|
      db.exec "DROP TABLE IF EXISTS #{table_name}"
    end
  end

  def create(table_name, fields)
    statement = String.build do |stmt|
      stmt << "CREATE TABLE #{table_name} ("
      stmt << "id INTEGER NOT NULL PRIMARY KEY, "
      stmt << fields.map{|name, type| "#{name} #{type}"}.join(",")
      stmt << ")"
    end
    open do |db|
      db.exec statement
    end
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
    return statement
  end

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  def select(table_name, fields, clause = "")
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{table_name}.#{name}"}.join(",")
      stmt << " FROM #{table_name} #{clause}"
    end
    return statement
  end

  # select_one is used by the find method.
  def select_one(table_name, fields)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{table_name}.#{name}"}.join(",")
      stmt << " FROM #{table_name}"
      stmt << " WHERE id=:id LIMIT 1"
    end
    return statement
  end

  def insert(table_name, fields)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{table_name} ("
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << ") VALUES ("
      stmt << fields.map{|name, type| "?"}.join(",")
      stmt << ")"
    end
    return statement
  end

  def last_val()
    return "SELECT LAST_INSERT_ROWID()"
  end

  # This will update a row in the database.
  def update(table_name, fields)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name} SET "
      stmt << fields.map{|name, type| "#{name}=?"}.join(",")
      stmt << " WHERE id=?"
    end
    return statement
  end

  # This will delete a row from the database.
  def delete(table_name)
    return "DELETE FROM #{table_name} WHERE id=?"
  end
end
