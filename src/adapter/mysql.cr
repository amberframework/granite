require "./base"
require "mysql"

# Mysql implementation of the Adapter
class Kemalyst::Adapter::Mysql < Kemalyst::Adapter::Base
  property pool : ConnectionPool(MySQL::Connection)
  property database : String
  
  def initialize(settings)
    host = env(settings["host"].to_s)
    port = env(settings["port"].to_s)
    username = env(settings["username"].to_s)
    password = env(settings["password"].to_s)
    @database = env(settings["database"].to_s)
    @pool = ConnectionPool.new(capacity: 20) do
       MySQL.connect(host, username, password, database, port.to_u16, nil)
    end
  end

  #Using TRUNCATE instead of DELETE so the id column resets to 0
  def clear(table_name)
    self.query("TRUNCATE #{table_name}")
  end
  
  # drop the table
  def drop(table_name)
    return self.query("DROP TABLE IF EXISTS #{table_name}")
  end
  
  def create(table_name, fields)
    statement = String.build do |stmt|
      stmt << "CREATE TABLE #{table_name} ("
      stmt << "id INT NOT NULL AUTO_INCREMENT, "
      stmt << fields.map{|name, type| "#{name} #{type}"}.join(",")
      stmt << ", PRIMARY KEY (id))"
      stmt << " ENGINE=InnoDB"
      stmt << " DEFAULT CHARACTER SET = utf8"
    end
    return self.query(statement)
  end

  # Migrate is an addative only approach.  It adds new columns but never
  # delete them to avoid data loss.  If the column type or size changes, a new
  # column will be created and the existing one will be renamed to
  # old_{tablename} then the data will be copied to the new column.  You may
  # need to perform insert queries if the migration cannot determine
  # how to convert the data for you.
  def migrate(table_name, fields)
    db_schema = self.query("SELECT column_name, data_type, character_maximum_length" \
                           " FROM information_schema.columns" \
                           " WHERE table_name = '#{table_name}'" \
                           " AND table_schema = '#{database}';")
    if db_schema && !db_schema.empty?
      prev = "id"
      fields.each do |name, type|
        #check to see if the field is in the db_schema
        columns = db_schema.select{|col| col[0] == name}
        if columns && columns.size > 0
          column = columns.first
          #check to see if the data_type matches
          if !type.downcase.includes?(column[1] as String)
            rename_field(table_name, name, "old_#{name}", type)
            add_field(table_name, name, type, prev)
            copy_field(table_name, "old_#{name}", name)
          else
            if size = column[2]
              if !type.downcase.includes?(size.to_s)
                rename_field(table_name, name, "old_#{name}", type)
                add_field(table_name, name, type, prev)
                copy_field(table_name, "old_#{name}", name)
              end
            end
          end
          #TODO: check to see if other flags match
          # Ignore if other flags are not specificed in SQL definition
        else
          add_field(table_name, name, type, prev)
        end
        prev = name
      end
    else
      create(table_name, fields)
    end
  end

  # Prune will remove fields that are not defined in the model.  This should
  # be used after you have successfully migrated the colunns and data. 
  # WARNING: Be aware that if you have fields in your database that are not
  # apart of the model, they will be dropped!
  def prune(table_name, fields)
    db_schema = self.query("SELECT column_name, data_type, character_maximum_length" \
                           " FROM information_schema.columns WHERE table_name = '#{table_name}';")
    if db_schema
      db_schema.each do |column|
        name = column[0] as String
        unless name == "id" || fields.has_key? name
          remove_field(table_name, name)
        end
      end
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
    return self.query(statement)
  end
  
  # rename a field in the table.
  def rename_field(table_name, old_name, new_name, type)
    statement = String.build do |stmt|
      stmt << "ALTER TABLE #{table_name} CHANGE"
      stmt << " #{old_name} #{new_name} #{type}"
    end
    return self.query(statement)
  end

  def remove_field(table_name, name)
    statement = String.build do |stmt|
      stmt << "ALTER TABLE #{table_name} DROP COLUMN"
      stmt << " #{name}"
    end
    return self.query(statement)
  end
 
  # Copy data from one column to another
  def copy_field(table_name, from, to)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name}"
      stmt << " SET #{to} = #{from}"
    end
    return self.query(statement)
  end
  
  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  def select(table_name, fields, clause = "", params = {} of String => String)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{table_name}.#{name}"}.join(",")
      stmt << " FROM #{table_name} #{clause}"
    end
    return self.query(statement, params, fields)
  end
  
  # select_one is used by the find method.
  def select_one(table_name, fields, id)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{table_name}.#{name}"}.join(",")
      stmt << " FROM #{table_name}"
      stmt << " WHERE id=:id LIMIT 1"
    end
    return self.query(statement, {"id" => id})
  end

  def insert(table_name, fields, params)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{table_name} ("
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << ") VALUES ("
      stmt << fields.map{|name, type| ":#{name}"}.join(",")
      stmt << ")"
    end
    self.query(statement, params)
    results = self.query("SELECT LAST_INSERT_ID()")
    if results
      return results[0][0] as Int64
    end
  end
  
  # This will update a row in the database.
  def update(table_name, fields, id, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name} SET "
      stmt << fields.map{|name, type| "#{name}=:#{name}"}.join(",")
      stmt << " WHERE id=:id"
    end
    if id
      params["id"] = "#{id}"
    end
    return self.query(statement, params, fields)
  end
  
  # This will delete a row from the database.
  def delete(table_name, id)
    return self.query("DELETE FROM #{table_name} WHERE id=:id", {"id" => id})
  end

  def query(statement : String, params = {} of String => String, fields = {} of Symbol => String)
    results = nil
    
    if conn = @pool.connection
      begin
        results = MySQL::Query.new(statement, scrub_params(params)).run(conn)
      ensure
        @pool.release
      end
    end
    return results
  end

  alias SUPPORTED_TYPES = (Nil | String | Float64 | Time | Int32 | Int64 | Bool | MySQL::Types::Date)

  private def scrub_params(params)
    new_params = {} of String => SUPPORTED_TYPES
    params.each do |key, value|
      if value.is_a? SUPPORTED_TYPES
        new_params[key] = value
      end
    end
    return new_params
  end

end

