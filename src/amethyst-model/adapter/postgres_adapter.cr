# require "pg"

# class Amethyst::Model::PostgresAdapter < Amethyst::Model::BaseAdapter

#   def initialize(@host, @username, @password, @database, @port)
#     @connection =
#       "postgres://#{@username}:#{@password}@#{@host}:#{@port}/#{@database}"
#   end

#   def query(query, params = {} of String => String)
#     conn = PG.connect(@connection)
#     if conn
#       begin
#         results = conn.exec(query)
#         return results.rows
#       ensure
#         conn.close
#       end
#     end
#     return [] of String
#   end

#   def insert(query, params = {} of String => String)
#     conn = PG.connect(@connection)
#     if conn
#       begin
#         conn.exec(query)
#         results = conn.exec("SELECT LAST_INSERT_ID()") as Array
#         id = results.rows[0][0]
#       ensure
#         conn.close
#       end
#     end
#     return id
#   end

#   def update(query, params = {} of String => String)
#     conn = PG.connect(@connection)
#     if conn
#       begin
#         conn.exec(query)
#       ensure
#         conn.close
#       end
#     end
#     return true
#   end

# end

