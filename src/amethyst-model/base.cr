require "yaml"

abstract class Amethyst::Model::Base

  # specify the database adapter you will be using for this model. 
  # mysql, postgresql, sqlite, etc.
  macro adapter(name)
    unless @@database
      yaml_file = File.read("config/database.yml")
      yaml = YAML.load(yaml_file) as Hash(YAML::Type, YAML::Type)
      settings = yaml["{{name.id}}"] as Hash(YAML::Type, YAML::Type)
      settings.each do |key, value|
        if value.is_a? String && value.starts_with? "$"
          settings[key] = env(value)
        end
      end
      @@database = Amethyst::Model::{{name.id.capitalize}}Adapter.new(settings)
    end
  end  
  
  # private method used to lookup the environment variable if exists
  private def self.env(value)
    value = value.gsub("${","").gsub("}", "")
    if ENV.has_key? value
      return ENV[value]
    else
      return ""
    end
  end
  
  # from_sql creates an instance of the model for each row returned from the
  # query.  All of the data is properly mapped to the fields in the results.
  abstract def from_sql(results : Array)

  # query performs the select statement and calls the from_sql with the
  # results.
  def self.query(table_name, fields, clause, params = {} of String => String)
    rows = [] of self
    if db = @@database
      results = db.select(table_name, fields, clause, params)
      if results.is_a?(Array)
        if results.size > 0
          results.each do |result|
            rows << self.from_sql(result)
          end
        end
      end
    end
    return rows
  end

  # query_one is a convenience method for only returning the first instance of a
  # query.
  def self.query_one(table_name, fields, id)
    row = nil
    if db = @@database
      results = db.select_one(table_name, fields, id)
      if results.is_a?(Array)
        if results.size > 0
          results.each do |result|
            row = self.from_sql(result)
          end
        end
      end
    end
    return row
  end
end


