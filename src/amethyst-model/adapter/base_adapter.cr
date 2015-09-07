abstract class Amethyst::Model::BaseAdapter

  abstract def connect(settings)
  abstract def clear(table_name)
  abstract def drop(table_name)
  abstract def create(table_name, fields)
  abstract def select(table_name, fields, clause = "", params = {} of String => String)
  abstract def select_one(table_name, fields, id)
  abstract def insert(table_name, fields, params)
  abstract def update(table_name, fields, id, params)
  abstract def delete(table_name, id)

  #abstract def query(query, params = {} of String => String)
  #abstract def insert(query, params = {} of String => String)
  #abstract def update(query, params = {} of String => String)

  private def env(value)
    value = value.gsub("${","").gsub("}", "")
    return ENV[value] if ENV.has_key? value
    return ""
  end
  
end
