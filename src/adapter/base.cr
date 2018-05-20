require "../granite"
require "db"

# The Base Adapter specifies the interface that will be used by the model
# objects to perform actions against a specific database.  Each adapter needs
# to implement these methods.
abstract class Granite::Adapter::Base
  property database : DB::Database

  def initialize(adapter : String)
    if url = ENV["DATABASE_URL"]? || Granite.settings.database_url || replace_env_vars(settings(adapter)["database"].to_s)
      @database = DB.open(url)
    else
      raise "database url needs to be set in the config/database.yml or DATABASE_URL environment variable"
    end
  end

  DATABASE_YML = "config/database.yml"

  def settings(adapter : String)
    if File.exists?(DATABASE_YML) &&
       (yaml = YAML.parse(File.read DATABASE_YML)) &&
       (settings = yaml[adapter])
      settings
    else
      return {"database": ""}
    end
  end

  def open(&block)
    yield @database
  end

  def log(query : String, params = [] of String) : Nil
    Granite.settings.logger.info "#{query}: #{params}"
  end

  # remove all rows from a table and reset the counter on the id.
  abstract def clear(table_name)

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  abstract def select(table_name, fields, clause = "", params = nil, &block)

  # This will insert a row in the database and return the id generated.
  abstract def insert(table_name, fields, params, lastval) : Int64

  # This will insert an array of models as one insert statement
  abstract def import(table_name : String, primary_name : String, auto : String, fields, model_array, **options)

  # This will update a row in the database.
  abstract def update(table_name, primary_name, fields, params)

  # This will delete a row from the database.
  abstract def delete(table_name, primary_name, value)

  # method used to replace the environment variable if exists
  private def replace_env_vars(url)
    Granite::Adapter::Base.env(url)
  end

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

  # class level method so we can test it
  def self.env(url)
    regex = /\$\{(.*?)\}/
    if regex.match(url)
      url = url.gsub(regex) do |match|
        ENV[match.gsub("${", "").gsub("}", "")]
      end
    else
      return url
    end
  end
end
