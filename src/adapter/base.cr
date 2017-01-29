require "../kemalyst-model"
require "db"

# The Base Adapter specifies the interface that will be used by the model
# objects to perform actions against a specific database.  Each adapter needs
# to implement these methods.
abstract class Kemalyst::Adapter::Base
  property url : String

  def initialize(settings)
    @url = env(settings["database"].to_s)
  end

  def open(&block)
    db = DB.open(@url)
    begin
      yield db
    ensure
      db.close
    end
  end

  # remove all rows from a table and reset the counter on the id.
  abstract def clear(table_name)

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  abstract def select(table_name, fields, clause = "", params = nil, &block)

  # select_one is used by the find method.
  # abstract def select_one(table_name, fields, id, &block)

  # This will insert a row in the database and return the id generated.
  abstract def insert(table_name, fields, params) : Int64

  # This will update a row in the database.
  abstract def update(table_name, fields, params)

  # This will delete a row from the database.
  abstract def delete(table_name, id)

  # method used to lookup the environment variable if exists
  private def env(value)
    env_var = value.gsub("${", "").gsub("}", "")
    if ENV.has_key? env_var
      return ENV[env_var]
    else
      return value
    end
  end
end
