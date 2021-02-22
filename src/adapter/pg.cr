require "./base"
require "pg"

# PostgreSQL implementation of the Adapter
class Granite::Adapter::Pg < Granite::Adapter::Base
  QUOTING_CHAR = '"'

  module Schema
    TYPES = {
      "Float32"        => "REAL",
      "Float64"        => "DOUBLE PRECISION",
      "String"         => "TEXT",
      "AUTO_Int32"     => "SERIAL",
      "AUTO_Int64"     => "BIGSERIAL",
      "AUTO_UUID"      => "UUID",
      "UUID"           => "UUID",
      "created_at"     => "TIMESTAMP",
      "updated_at"     => "TIMESTAMP",
      "Array(String)"  => "TEXT[]",
      "Array(Int16)"   => "SMALLINT[]",
      "Array(Int32)"   => "INT[]",
      "Array(Int64)"   => "BIGINT[]",
      "Array(Float32)" => "REAL[]",
      "Array(Float64)" => "DOUBLE PRECISION[]",
      "Array(Bool)"    => "BOOLEAN[]",
    }
  end

  # remove all rows from a table and reset the counter on the id.
  def clear(table_name : String)
    statement = "DELETE FROM #{quote(table_name)}"

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
      stmt << fields.map { |name| "$#{fields.index(name).not_nil! + 1}" }.join(", ")
      stmt << ")"

      stmt << " RETURNING #{quote(lastval)}" if lastval
    end

    last_id = -1_i64
    elapsed_time = Time.measure do
      open do |db|
        if lastval
          last_id = db.scalar(statement, args: params).as(Int32 | Int64).to_i64
        else
          db.exec statement, args: params
        end
      end
    end

    log statement, elapsed_time, params

    last_id
  end

  def import(table_name : String, primary_name : String, auto : Bool, fields, model_array, **options)
    params = [] of Granite::Columns::Type
    # PG fails when inserting null into AUTO INCREMENT PK field.
    # If AUTO INCREMENT is TRUE AND all model's pk are nil, remove PK from fields list for AUTO INCREMENT to work properly
    fields.reject! { |field| field == primary_name } if model_array.all? { |m| m.to_h[primary_name].nil? } && auto
    index = 0

    statement = String.build do |stmt|
      stmt << "INSERT"
      stmt << " INTO #{quote(table_name)} ("
      stmt << fields.map { |field| quote(field) }.join(", ")
      stmt << ") VALUES "

      model_array.each do |model|
        model.set_timestamps
        next unless model.valid?
        stmt << '('
        stmt << fields.map_with_index { |_f, idx| "$#{index + idx + 1}" }.join(',')
        params.concat fields.map { |field| model.read_attribute field }
        stmt << "),"
        index += fields.size
      end
    end.chomp(',')

    if options["update_on_duplicate"]?
      if columns = options["columns"]?
        statement += " ON CONFLICT (#{quote(primary_name)}) DO UPDATE SET "
        columns << "updated_at" if fields.includes? "updated_at"
        columns.each do |key|
          statement += "#{quote(key)}=EXCLUDED.#{quote(key)}, "
        end
      end
      statement = statement.chomp(", ")
    elsif options["ignore_on_duplicate"]?
      statement += " ON CONFLICT DO NOTHING"
    end

    elapsed_time = Time.measure do
      open do |db|
        db.exec statement, args: params
      end
    end

    log statement, elapsed_time, params
  end

  # This will update a row in the database.
  def update(table_name : String, primary_name : String, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=$#{fields.index(name).not_nil! + 1}" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=$#{fields.size + 1}"
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
    statement = "DELETE FROM #{quote(table_name)} WHERE #{quote(primary_name)}=$1"

    elapsed_time = Time.measure do
      open do |db|
        db.exec statement, value
      end
    end

    log statement, elapsed_time, value
  end

  protected def ensure_clause_template(clause : String) : String
    if clause.includes?("?")
      num_subs = clause.count("?")

      num_subs.times do |i|
        clause = clause.sub("?", "$#{i + 1}")
      end
    end

    clause
  end
end
