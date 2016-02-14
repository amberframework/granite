# The Base Adapter specifies the interface that will be used by the model
# objects to perform actions against a specific database.  Each adapter needs
# to implement these methods.
abstract class Amethyst::Model::Adapter::Base
  
  # clear will remove all rows from a table and reset the counter on the id.
  abstract def clear(table_name)
  
  # drop will drop the table
  abstract def drop(table_name)
  
  # create will create the table based on the fields specified in the
  # sql_mapping defined in the model.
  abstract def create(table_name, fields)
  
  # migrate is an addative only approach and should be safe to call at any
  # tiem.  It alter existing columns or add new columns but never delete them
  # to avoid data loss.  If a column cannot be altered without losing data, a
  # new column will be created and the existing one will be renamed to _old.
  # You may need to perform select insert queries if the migration cannot
  # determine how to convert the data for you.
  #abstract def migrate(table_name, fields)

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  abstract def select(table_name, fields, clause = "", params = {} of String => String)

  # select_one is used by the find method.
  abstract def select_one(table_name, fields, id)

  # This will insert a row in the database and return the id generated.
  abstract def insert(table_name, fields, params)

  # This will update a row in the database.
  abstract def update(table_name, fields, id, params)

  # This will delete a row from the database.
  abstract def delete(table_name, id)
end
