#require "./amethyst-model/base_adapter"
# require "pg"

# class Amethyst::Model::PostgresqlAdapter < Amethyst::Model::BaseAdapter

#   def initialize(settings)
#     @host = settings["host"] as String
#     @port = settings["port"] as String
#     @username = settings["username"] as String
#     @password = settings["password"] as String
#     @database = settings["database"] as String
#     @connection =
#       "postgres://#{@username}:#{@password}@#{@host}:#{@port}/#{@database}"
#   end

#   # DDL
#   def clear(table_name)
#     self.query("DELETE FROM #{table_name}")
#   end

#   def drop(table_name)
#     return self.query("DROP TABLE IF EXISTS #{table_name}")
#   end

#   def create(table_name, fields)
#     statement = String.build do |stmt|
#       stmt << "CREATE TABLE #{table_name} ("
#       stmt << "id SERIAL PRIMARY KEY, "
#       stmt << fields.map{|name, type| "#{name} #{type}"}.join(",")
#       stmt << ")"
#     end
#     return self.query(statement)
#   end

#   def select(table_name, fields, clause = "", params = {} of String => String)
#     statement = String.build do |stmt|
#       stmt << "SELECT "
#       stmt << fields.map{|name, type| "#{name}"}.join(",")
#       stmt << " FROM #{table_name} #{clause}"
#     end
#     return self.query(statement, params, fields)
#   end
  
#   def select_one(table_name, fields, id)
#     statement = String.build do |stmt|
#       stmt << "SELECT "
#       stmt << fields.map{|name, type| "#{name}"}.join(",")
#       stmt << " FROM #{table_name}"
#       stmt << " WHERE id=:id LIMIT 1"
#     end
#     return self.query(statement, {"id" => id}, fields)
#   end

#   def insert(table_name, fields, params)
#     statement = String.build do |stmt|
#       stmt << "INSERT INTO #{table_name} ("
#       stmt << fields.map{|name, type| "#{name}"}.join(",")
#       stmt << ") VALUES ("
#       stmt << fields.map{|name, type| ":#{name}"}.join(",")
#       stmt << ") RETURNING id"
#     end
#     results = self.query(statement, params, fields)
#     if results
#       return results[0][0]
#     end
#   end
  
#   def update(table_name, fields, id, params)
#     statement = String.build do |stmt|
#       stmt << "UPDATE #{table_name} SET "
#       stmt << fields.map{|name, type| "#{name}=:#{name}"}.join(",")
#       stmt << " WHERE id=:id"
#     end
#     if id
#       params["id"] = "#{id}"
#     end
#     return self.query(statement, params, fields)
#   end
  
#   def delete(table_name, id)
#     return self.query("DELETE FROM #{table_name} WHERE id=:id", {"id" => id})
#   end

#   # DML
#   def query(query, params = {} of String => String, fields = {} of Symbol => String)
#     if params
#       query, params = scrub_query_and_params(query, params, fields)
#     end
#     conn = PG.connect(@connection)
#     if conn
#       begin
#         puts "QUERY: #{query} PARAMS: #{params.inspect}"
#         results = conn.exec(query, params)
#         puts "RESULTS: #{results.inspect}"
#         return results.rows
#       ensure
#         conn.finish
#       end
#     end
#     return [] of String
#   end

#   alias SUPPORTED_TYPES = (Nil | String | Int32 | Int16 | Int64 | Float32 | Float64 | Bool | Time | Char)
#   private def scrub_query_and_params(query, params, fields)
#     new_params = [] of SUPPORTED_TYPES
#     params.each_with_index do |key, value, index|
#       if value.is_a? SUPPORTED_TYPES
#         query = query.gsub(":#{key}", "$#{index+1}#{lookup_type(fields,key)}")
#         new_params << value
#       end
#     end
#     return query, new_params
#   end

#   # I can't find a way to lookup a symbol using a string.  This method
#   # unfortunately traverses the map to find it.
#   private def lookup_type(fields, key_as_string)
#     if key_as_string == "id"
#       return "::int"
#     else
#       fields.each do |key, pg_type|
#         if key.to_s == key_as_string
#           return "::#{pg_type.downcase}"
#         end
#       end
#     end
#     return ""
#   end

# end

