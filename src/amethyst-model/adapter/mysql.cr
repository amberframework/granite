require "../*"
require "./base"
require "mysql"

class Amethyst::Model::Adapter::Mysql < Amethyst::Model::Adapter::Base

  def initialize(settings)
    host = settings["host"] as String
    port = settings["port"] as String
    username = settings["username"] as String
    password = settings["password"] as String
    database = settings["database"] as String
    @pool = ConnectionPool.new(capacity: 20, timeout: 0.01) do
       MySQL.connect(host, username, password, database, port.to_u16, nil)
    end
  end

  # DDL
  def clear(table_name)
    return self.query("TRUNCATE #{table_name}")
  end

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

  def select(table_name, fields, clause = "", params = {} of String => String)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{name}"}.join(",")
      stmt << " FROM #{table_name} #{clause}"
    end
    return self.query(statement, params)
  end
  
  def select_one(table_name, fields, id)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map{|name, type| "#{name}"}.join(",")
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
    results = self.queries([statement, "SELECT LAST_INSERT_ID()"], params) 
    if results
      return results[0][0]
    end
  end
  
  def update(table_name, fields, id, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{table_name} SET "
      stmt << fields.map{|name, type| "#{name}=:#{name}"}.join(",")
      stmt << " WHERE id=:id"
    end
    params["id"] = "#{id}"
    return self.query(statement, params)
  end
  
  def delete(table_name, id)
    return self.query("DELETE FROM #{table_name} WHERE id=:id", {"id" => id})
  end

  def query(query, params = {} of String => String)
    return queries([query], params)
  end

  def queries(queries, params = {} of String => String)
    results = nil
    
    if conn = @pool.connection
      begin
        queries.each do |query|
          results = MySQL::Query.new(query, params).run(conn)
        end
      ensure
        @pool.release
      end
    end
    return results
  end

end
