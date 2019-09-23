require "./base"
require "mysql"

# Mysql implementation of the Adapter
class Granite::Adapter::Mysql < Granite::Adapter::Base
  QUOTING_CHAR = '`'

  module Schema
    TYPES = {
      "AUTO_Int32" => "INT NOT NULL AUTO_INCREMENT",
      "AUTO_Int64" => "BIGINT NOT NULL AUTO_INCREMENT",
      "AUTO_UUID"  => "CHAR(36)",
      "Float64"    => "DOUBLE",
      "UUID"       => "CHAR(36)",
      "created_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
      "updated_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
    }
  end

  # Using TRUNCATE instead of DELETE so the id column resets to 0
  def clear(table_name : String)
    statement = "TRUNCATE #{quote(table_name)}"

    elapsed_time = Time.measure do
      open do |db|
        db.exec statement
      end
    end

    log statement, elapsed_time
  end

  def insert(table_name : String, fields, params, lastval) : Int64
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << fields.map { |name| "#{quote(name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << fields.map { |_name| "?" }.join(", ")
      stmt << ")"
    end

    last_id = -1_i64
    elapsed_time = Time.measure do
      open do |db|
        db.using_connection do |conn|
          conn.exec statement, args: params
          last_id = conn.scalar(last_val()).as(Int64) if lastval
        end
      end
    end

    log statement, elapsed_time, params

    last_id
  end

  def import(table_name : String, primary_name : String, auto : Bool, fields, model_array, **options)
    params = [] of Granite::Columns::Type

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

    elapsed_time = Time.measure do
      open do |db|
        db.exec statement, args: params
      end
    end

    log statement, elapsed_time, params
  end

  private def last_val : String
    "SELECT LAST_INSERT_ID()"
  end

  # This will update a row in the database.
  def update(table_name : String, primary_name : String, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=?" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=?"
    end

    elapsed_time = Time.measure do
      open do |db|
        db.exec statement, args: params
      end
    end

    log statement, elapsed_time, params
  end

  # This will delete a row from the database.
  def delete(table_name : String, primary_name : String, value)
    statement = "DELETE FROM #{quote(table_name)} WHERE #{quote(primary_name)}=?"

    elapsed_time = Time.measure do
      open do |db|
        db.exec statement, value
      end
    end

    log statement, elapsed_time, value
  end
end
