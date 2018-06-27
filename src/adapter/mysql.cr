require "./base"
require "mysql"

# Mysql implementation of the Adapter
class Granite::Adapter::Mysql < Granite::Adapter::Base
  QUOTING_CHAR = '`'

  module Schema
    TYPES = {
      "AUTO_Int32" => "INT NOT NULL AUTO_INCREMENT",
      "AUTO_Int64" => "BIGINT NOT NULL AUTO_INCREMENT",
      "created_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
      "updated_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
    }
  end

  # Using TRUNCATE instead of DELETE so the id column resets to 0
  def clear(table_name)
    statement = "TRUNCATE #{quote(table_name)}"

    log statement

    open do |db|
      db.exec statement
    end
  end

  # select performs a query against a table.  The query object containes table_name,
  # fields (configured using the sql_mapping directive in your model), and an optional
  # raw query string.  The clause and params is the query and params that is passed
  # in via .all() method
  def select(query : Granite::Select::Container, clause = "", params = [] of DB::Any, &block)
    statement = query.custom || String.build do |stmt|
      stmt << "SELECT "
      stmt << query.fields.map { |name| "#{quote(query.table_name)}.#{quote(name)}" }.join(", ")
      stmt << " FROM #{quote(query.table_name)} #{clause}"
    end

    log statement, params

    open do |db|
      db.query statement, params do |rs|
        yield rs
      end
    end
  end

  def insert(table_name, fields, params, lastval)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << fields.map { |name| "#{quote(name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << fields.map { |_name| "?" }.join(", ")
      stmt << ")"
    end

    log statement, params

    open do |db|
      db.using_connection do |conn|
        conn.exec statement, params
        if lastval
          return conn.scalar(last_val()).as(Int64)
        else
          return -1_i64
        end
      end
    end
  end

  def import(table_name : String, primary_name : String, auto : String, fields, model_array, **options)
    params = [] of DB::Any

    statement = String.build do |stmt|
      stmt << "INSERT"
      stmt << " IGNORE" if options["ignore_on_duplicate"]?
      stmt << " INTO #{quote(table_name)} ("
      stmt << fields.map { |field| quote(field) }.join(", ")
      stmt << ") VALUES "

      model_array.each do |model|
        model.set_timestamps
        next unless model.valid?
        stmt << "("
        stmt << Array.new(fields.size, '?').join(',')
        params.concat fields.map { |field| model.read_attribute field }
        stmt << "),"
      end
    end.chomp(',')

    if options["update_on_duplicate"]?
      if columns = options["columns"]?
        statement += " ON DUPLICATE KEY UPDATE "
        columns << "updated_at" if fields.includes? "updated_at"
        columns.each do |key|
          statement += "#{quote(key)}=VALUES(#{quote(key)}), "
        end
        statement = statement.chomp(", ")
      end
    end

    log statement, params

    open do |db|
      db.exec statement, params
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
