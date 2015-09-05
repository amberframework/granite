abstract class BaseAdapter
  abstract def connect(host, username, password, database, port)
  abstract def query(query, params = {} of String => String)
  abstract def insert(query, params = {} of String => String)
  abstract def update(query, params = {} of String => String)
end
