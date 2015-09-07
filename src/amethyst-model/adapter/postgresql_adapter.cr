require "pg"

class Amethyst::Model::PostgresqlAdapter < Amethyst::Model::BaseAdapter

  def initialize(settings)
    @host = settings["host"] as String
    @host = env(@host) if @host.starts_with? "$"

    @port = settings["port"] as String
    @port = env(@port) if @port.starts_with? "$"
    
    @username = settings["username"] as String
    @username = env(@username) if @username.starts_with? "$"
    
    @password = settings["password"] as String
    @password = env(@password) if @password.starts_with? "$"
    
    @database = settings["database"] as String
    @database = env(@database) if @database.starts_with? "$"

    @connection =
      "postgres://#{@username}:#{@password}@#{@host}:#{@port}/#{@database}"
  end

  # DDL
  def clear(table_name)
    self.query("DELETE FROM #{table_name}")
  end

  def drop(table_name)
    return self.query("DROP TABLE IF EXISTS #{table_name}")
  end

  def create(table_name, fields)
    statement = String.build do |stmt|
      stmt << "CREATE TABLE #{table_name} ("
      stmt << "id SERIAL PRIMARY KEY, "
      stmt << fields.map{|name, type| "#{name} #{type}"}.join(",")
      stmt << ")"
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
      stmt << ") RETURNING id"
    end
    results = self.query(statement, params)
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
    if id
      params["id"] = "#{id}"
    end
    return self.query(statement, params)
  end
  
  def delete(table_name, id)
    return self.query("DELETE FROM #{table_name} WHERE id=:id", {"id" => id})
  end

  # DML
  def query(query, params = {} of String => String)
    if params
      query, params = map_hash_to_array(query, params)
    end
    conn = PG.connect(@connection)
    if conn
      begin
        results = conn.exec(query, params)
        return results.rows
      ensure
        conn.finish
      end
    end
    return [] of String
  end

  def map_hash_to_array(query, params)
    new_params = [] of (Nil | String | Int32 | Int16 | Int64 | Float32 | Float64 | Bool | Time | Char | Hash(String, JSON::Type) | Array(JSON::Type))
    params.each_with_index do |key, value, index|
      query = query.gsub(":#{key}", "$#{index+1}")
      new_params << value
    end
    return query, new_params
  end
end

