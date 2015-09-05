# require "sqlite3"

# class Amethyst::Model::SqliteAdapter < Amethyst::Model::BaseAdapter

#   def initialize(@host, @username, @password, @database, @port)
#   end

#   def query(query, params = {} of String => String)
#     conn = SQLite3::Database.new( @database )
#     if conn
#       begin
#         results = conn.execute(query)
#       ensure
#         conn.close
#       end
#     end
#     return results
#   end
  
#   def insert(query, params = {} of String => String)
#     conn = SQLite3::Database.new( @database )
#     if conn
#       begin
#         conn.execute(query)
#         results = conn.execute("SELECT LAST_INSERT_ID()") as Array
#         id = results[0][0]
#       ensure
#         conn.close
#       end
#     end
#     return id
#   end
  
#   def update(query, params = {} of String => String)
#     conn = SQLite3::Database.new( @database )
#     if conn
#       begin
#         conn.execute(query)
#       ensure
#         conn.close
#       end
#     end
#     return true
#   end

# end

