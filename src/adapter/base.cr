require "../granite"
require "db"

# The Base Adapter specifies the interface that will be used by the model
# objects to perform actions against a specific database.  Each adapter needs
# to implement these methods.
abstract class Granite::Adapter::Base
  getter name : String
  getter url : String
  private property database : DB::Database

  def initialize(connection_hash : NamedTuple(url: String, name: String))
    @name = connection_hash[:name]
    @url = connection_hash[:url]
    @database = DB.open(@url)
  end

  def open(&block)
    yield database
  end

  def log(query : String, params = [] of String) : Nil
    Granite.settings.logger.info "#{query}: #{params}"
  end

  # remove all rows from a table and reset the counter on the id.
  abstract def clear(table_name)

  # select performs a query against a table.  The query object containes table_name,
  # fields (configured using the sql_mapping directive in your model), and an optional
  # raw query string.  The clause and params is the query and params that is passed
  # in via .all() method
  abstract def select(query : Granite::Select::Container, clause = "", params = nil, &block)

  # This will insert a row in the database and return the id generated.
  abstract def insert(table_name, fields, params, lastval) : Int64

  # This will insert an array of models as one insert statement
  abstract def import(table_name : String, primary_name : String, auto : String, fields, model_array, **options)

  # This will update a row in the database.
  abstract def update(table_name, primary_name, fields, params)

  # This will delete a row from the database.
  abstract def delete(table_name, primary_name, value)

  module Schema
    TYPES = {
      "Bool"    => "BOOL",
      "Float32" => "FLOAT",
      "Float64" => "REAL",
      "Int32"   => "INT",
      "Int64"   => "BIGINT",
      "String"  => "VARCHAR(255)",
      "Time"    => "TIMESTAMP",
    }
  end

  # Use macro in order to read a constant defined in each subclasses.
  macro inherited
    # quotes table and column names
    def quote(name : String) : String
      char = QUOTING_CHAR
      char + name.gsub(char, "#{char}#{char}") + char
    end

    # converts the crystal class to database type of this adapter
    def self.schema_type?(key : String)
      Schema::TYPES[key]? || Granite::Adapter::Base::Schema::TYPES[key]?
    end
  end
end
