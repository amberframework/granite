require "./base"
require "mysql"

# Mysql implementation of the Adapter
class Kemalyst::Adapter::Mysql < Kemalyst::Adapter::Base
  # Using TRUNCATE instead of DELETE so the id column resets to 0
  def clear(table_name)
    open do |db|
      db.exec "TRUNCATE #{table_name}"
    end
  end

  # Add a field to the table. Your field will be added after the `previous` if
  # specified.
  def add_field(table_name, name, type, previous = nil)
    statement = String.build do |stmt|
      stmt << "ALTER TABLE #{table_name} ADD COLUMN"
      stmt << " #{name} #{type}"
      if previous
        stmt << " AFTER #{previous}"
      end
    end
    return statement
  end

  # rename a field in the table.
  def rename_field(table_name, old_name, new_name, type)
    statement = String.build do |stmt|
      stmt << "ALTER TABLE #{table_name} CHANGE"
      stmt << " #{old_name} #{new_name} #{type}"
    end
    return statement
  end

  def remove_field(table_name, name)
    statement = String.build do |stmt|
      stmt << "ALTER TABLE #{table_name} DROP COLUMN"
      stmt << " #{name}"
    end
    return statement
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
  def select(table_name, fields, clause = "", params = nil, &block)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map { |name| "#{table_name}.#{name}" }.join(",")
      stmt << " FROM #{table_name} #{clause}"
    end
    open do |db|
      db.query statement, params do |rs|
        yield rs
      end
    end
  end

  # select_one is used by the find method.
  # it checks id by default, but one can
  # pass another field.
  def select_one(table_name, fields, field, id, &block)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map { |name| "#{table_name}.#{name}" }.join(",")
      stmt << " FROM #{table_name}"
      stmt << " WHERE #{field}=? LIMIT 1"
    end
    open do |db|
      db.query_one? statement, id do |rs|
        yield rs
      end
    end
  end

  def insert(table_name, fields, params)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{table_name} ("
      stmt << fields.map { |name| "#{name}" }.join(",")
      stmt << ") VALUES ("
      stmt << fields.map { |name| "?" }.join(",")
      stmt << ")"
    end
    open do |db|
      db.exec statement, params
      return db.scalar(last_val()).as(Int64)
    end
  end

  private def last_val
    return "SELECT LAST_INSERT_ID()"
  end

  # This will update a row in the database.
  def update(table_name, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name} SET "
      stmt << fields.map { |name| "#{name}=?" }.join(",")
      stmt << " WHERE id=?"
    end
    open do |db|
      db.exec statement, params
    end
  end

  # This will delete a row from the database.
  def delete(table_name, id)
    open do |db|
      db.exec "DELETE FROM #{table_name} WHERE id=?", id
    end
  end
end
