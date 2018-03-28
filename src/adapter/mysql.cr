require "./base"
require "mysql"

# Mysql implementation of the Adapter
class Granite::Adapter::Mysql < Granite::Adapter::Base
  QUOTING_CHAR = '`'

  # Using TRUNCATE instead of DELETE so the id column resets to 0
  def clear(table_name)
    statement = "TRUNCATE #{quote(table_name)}"

    log statement

    open do |db|
      db.exec statement
    end
  end

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  def select(table_name, fields, clause = "", params = [] of DB::Any, &block)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
      stmt << " FROM #{quote(table_name)} #{clause}"
    end

    log statement, params

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
      stmt << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
      stmt << " FROM #{quote(table_name)}"
      stmt << " WHERE #{quote(field)}=? LIMIT 1"
    end

    log statement, id

    open do |db|
      db.query_one? statement, id do |rs|
        yield rs
      end
    end
  end

  def insert(table_name, fields, params, lastval)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << fields.map { |name| "#{quote(name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << fields.map { |name| "?" }.join(", ")
      stmt << ")"
    end

    log statement, params

    open do |db|
      db.exec statement, params
      if lastval
        return db.scalar(last_val()).as(Int64)
      else
        return -1_i64
      end
    end
  end

  private def last_val
    return "SELECT LAST_INSERT_ID()"
  end

  # This will update a row in the database.
  def update(table_name, primary_name, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=?" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=?"
    end

    log statement, params

    open do |db|
      db.exec statement, params
    end
  end

  # This will delete a row from the database.
  def delete(table_name, primary_name, value)
    statement = "DELETE FROM #{quote(table_name)} WHERE #{quote(primary_name)}=?"

    log statement, value

    open do |db|
      db.exec statement, value
    end
  end
end
