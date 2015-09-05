require "yaml"
require "./adapter/*"

abstract class Amethyst::Model::Base

  macro adapter(name)
    unless @@database
      yaml_file = File.read("config/database.yml")
      yaml = YAML.load(yaml_file) as Hash
      settings = yaml["{{name.id}}"] as Hash(YAML::Type, YAML::Type)
      @@database = {{name.id.capitalize}}Adapter.new(settings)
    end
  end  

  abstract def or_mapping(results : Array)

  def self.query(query, params = {} of String => String)
    rows = [] of self
    if db = @@database
      results = db.query(query, params)
      if results.is_a?(Array)
        if results.size > 0
          results.each do |result|
            rows << or_mapping(result)
          end
        end
      end
    end
    return rows
  end

  def self.query_one(query, params = {} of String => String)
    row = nil
    rows = self.query(query, params)
    if rows && rows.size > 0
      row = rows[0]
    end
    return row
  end

  def insert(query, params = {} of String => String)
    if db = @@database
      id = db.insert(query, params)
    end
  end

  def update(query, params = {} of String => String)
    if db = @@database
      return db.update(query, params)
    end
    return false
  end
end

