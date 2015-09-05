abstract class Amethyst::Model::BaseAdapter

  abstract def connect(settings)
  abstract def query(query, params = {} of String => String)
  abstract def insert(query, params = {} of String => String)
  abstract def update(query, params = {} of String => String)

  private def env(value)
    value = value.gsub("${","").gsub("}", "")
    return ENV[value] if ENV.has_key? value
    return ""
  end
  
end
