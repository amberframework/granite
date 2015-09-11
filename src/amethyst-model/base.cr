require "yaml"

abstract class Amethyst::Model::Base

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
  
  private def self.env(value)
    value = value.gsub("${","").gsub("}", "")
    if ENV.has_key? value
      return ENV[value]
    else
      return ""
    end
  end
  
  abstract def from_sql(results : Array)

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


