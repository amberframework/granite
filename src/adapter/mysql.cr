require "./base"
require "mysql"

# Mysql implementation of the Adapter
class Kemalyst::Adapter::Mysql < Kemalyst::Adapter::Base
  #Using TRUNCATE instead of DELETE so the id column resets to 0
  def clear(table_name)
    open do |db|
      db.exec "TRUNCATE #{table_name}"
    end
  end

  # drop the table
  def drop(table_name)
    open do |db|
      db.exec "DROP TABLE IF EXISTS #{table_name}"
    end
  end

  private def create_statement(table_name, fields)
    statement = String.build do |stmt|
      stmt << "CREATE TABLE #{table_name} ("
      stmt << "id BIGINT NOT NULL AUTO_INCREMENT, "
      stmt << fields.map{|name, type| "#{name} #{type}"}.join(",")
      stmt << ", PRIMARY KEY (id))"
      stmt << " ENGINE=InnoDB"
      stmt << " DEFAULT CHARACTER SET=utf8"
    end
  end

  def create(table_name, fields)
    open do |db|
      db.exec create_statement(table_name, fields)
    end
  end

  private def schema_statement(table_name)
    return "SELECT column_name, data_type, character_maximum_length" \
           " FROM information_schema.columns" \
           " WHERE table_name = '#{table_name}';"
#           " AND table_schema = '#{database}';"
  end
  # Migrate is an addative only approach.  It adds new columns but never
  # delete them to avoid data loss.  If the column type or size changes, a new
  # column will be created and the existing one will be renamed to
  # old_{tablename} then the data will be copied to the new column.  You may
  # need to perform insert queries if the migration cannot determine
  # how to convert the data for you.
  def migrate(table_name, fields)
    open do |db|
      db_schema = db.query_all( schema_statement(table_name),
                               as: {String, String, Union(Int64, Nil)} )
      if db_schema && !db_schema.empty?
        prev = "id"
        fields.each do |name, type|
          #check to see if the field is in the db_schema
          columns = db_schema.select{|col| col[0] == name}
          if columns && columns.size > 0
            column = columns.first

            #check to see if the data_type matches
            if db_type = column[1].as(String)
              if !type.downcase.includes?(db_type)
                db.exec rename_field(table_name, name, "old_#{name}", type)
                db.exec add_field(table_name, name, type, prev)
                db.exec copy_field(table_name, "old_#{name}", name)
              else
                if size = column[2].as(Int64)
                  if !type.downcase.includes?(size.to_s)
                    db.exec rename_field(table_name, name, "old_#{name}", type)
                    db.exec add_field(table_name, name, type, prev)
                    db.exec copy_field(table_name, "old_#{name}", name)
                  end
                end
              end
            end
          else
            db.exec add_field(table_name, name, type, prev)
          end
          prev = name
        end
      else
        db.exec create_statement(table_name, fields)
      end
    end
  end

  # Prune will remove fields that are not defined in the model.  This should
  # be used after you have successfully migrated the colunns and data.
  # WARNING: Be aware that if you have fields in your database that are not
  # apart of the model, they will be dropped!
  def prune(table_name, fields)
    open do |db|
      names = [] of String
      db.query( schema_statement(table_name) ) do |results|
        results.each do
          name = results.read(String)
          unless name == "id" || fields.has_key? name
            names << name
          end
        end
      end
      names.each {|name| db.exec remove_field(table_name, name) }
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
    return statement
  end

  # rename a field in the table.
  def rename_field(table_name, old_name, new_name, type)
    statement = String.build do |stmt|
      stmt << "ALTER TABLE #{table_name} CHANGE"
      stmt << " #{old_name} #{new_name} #{type}"
    end
    return statement
  end

  def remove_field(table_name, name)
    statement = String.build do |stmt|
      stmt << "ALTER TABLE #{table_name} DROP COLUMN"
      stmt << " #{name}"
    end
    return statement
  end

  # Copy data from one column to another
  def copy_field(table_name, from, to)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name}"
      stmt << " SET #{to} = #{from}"
    end
    return statement
  end

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  def select(table_name, fields, clause = "")
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{table_name}.#{name}"}.join(",")
      stmt << " FROM #{table_name} #{clause}"
    end
    return statement
  end

  # select_one is used by the find method.
  def select_one(table_name, fields)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{table_name}.#{name}"}.join(",")
      stmt << " FROM #{table_name}"
      stmt << " WHERE id=? LIMIT 1"
    end
    return statement
  end

  def insert(table_name, fields)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{table_name} ("
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << ") VALUES ("
      stmt << fields.map{|name, type| "?"}.join(",")
      stmt << ")"
    end
    return statement
  end

  def last_val()
    return "SELECT LAST_INSERT_ID()"
  end

  # This will update a row in the database.
  def update(table_name, fields)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name} SET "
      stmt << fields.map{|name, type| "#{name}=?"}.join(",")
      stmt << " WHERE id=?"
    end
    return statement
  end

  # This will delete a row from the database.
  def delete(table_name)
    return "DELETE FROM #{table_name} WHERE id=?"
  end
end
