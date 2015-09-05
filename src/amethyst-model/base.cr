require "yaml"
require "./adapter/*"

abstract class Base

  def self.adapter
    unless @@adapter
      yaml_file = File.read("config/database.yml")
      yaml = YAML.load(yaml_file) as Hash
      settings = yaml[Base::App.settings.environment] as Hash(YAML::Type, YAML::Type)
      
      adapter_s = settings["adapter"] as String
      adapter_s = env(adapter_s) if adapter_s.starts_with? "$"
      
      host = settings["host"] as String
      host = env(host) if host.starts_with? "$"

      port = settings["port"] as String
      port = env(port) if port.starts_with? "$"
      
      username = settings["username"] as String
      username = env(username) if username.starts_with? "$"
      
      password = settings["password"] as String
      password = env(password) if password.starts_with? "$"
      
      database = settings["database"] as String
      database = env(database) if database.starts_with? "$"
      
      case adapter_s
      when "mysql" 
        @@adapter = MySQLAdapter.new(host, username, password, database, port)
      when "postgres"
        # @@adapter = PostgreSQLAdapter.new(host, username, password, database, port)
      when "sqlite"
      else
        raise "Adapter #{adapter_s} not found"
      end
    end
    return @@adapter
  end

  private def self.env(value)
    value = value.gsub("${","").gsub("}", "")
    return ENV[value] if ENV.has_key? value
    return ""
  end

  def self.query(query, params = {} of String => String)
    rows = [] of self
    if db = Base.adapter
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
    if db = Base.adapter
      id = db.insert(query, params)
    end
  end

  def update(query, params = {} of String => String)
    if db = Base.adapter
      return db.update(query, params)
    end
    return false
  end

  abstract def or_mapping(results : Array)
end

