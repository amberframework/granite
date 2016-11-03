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

  # drop the table
  abstract def drop(table_name)

  # create will create the table based on the fields specified in the
  # sql_mapping defined in the model.
  abstract def create(table_name, fields)

  # Migrate is an addative only approach.  It adds new columns but never
  # delete them to avoid data loss.  If the column type or size changes, a new
  # column will be created and the existing one will be renamed to
  # old_{tablename} then the data will be copied to the new column.  You may
  # need to perform insert queries if the migration cannot determine
  # how to convert the data for you.
  # abstract def migrate(table_name, fields)

  # Prune will remove fields that are not defined in the model.  This should
  # be used after you have successfully migrated the colunns and data.
  # WARNING: Be aware that if you have fields in your database that are not
  # apart of the model, they will be dropped!
  # abstract def prune(table_name, fields)

  # Add a field to the table. Your field will be added after the `previous` if
  # specified.
  abstract def add_field(table_name, name, type, previous = nil)

  # Rename a field in the table
  abstract def rename_field(table_name, old_name, new_name, type)

  # Remove a field in the table.
  abstract def remove_field(table_name, name)

  # Copy data from one column to another
  abstract def copy_field(table_name, from, to)

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  abstract def select(table_name, fields, clause = "")

  # select_one is used by the find method.
  abstract def select_one(table_name, fields)

  # This will insert a row in the database and return the id generated.
  abstract def insert(table_name, fields)

  # The last created sequence id
  abstract def last_val()

  # This will update a row in the database.
  abstract def update(table_name, fields)

  # This will delete a row from the database.
  abstract def delete(table_name)

  # method used to lookup the environment variable if exists
  def env(value)
    env_var = value.gsub("${","").gsub("}", "")
    if ENV.has_key? env_var
      return ENV[env_var]
    else
      return value
    end
  end
end

