require "yaml"

# Kemalyst::Model is the base class for your model objects.
class Kemalyst::Model
  VERSION = "0.1.0"
  property errors : Array(String)?

  def errors
    @errors ||= [] of String
  end

  # specify the database adapter you will be using for this model. 
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    def self.settings
      yaml_file = File.read("config/database.yml")
      yaml = YAML.parse(yaml_file)
      settings = yaml["{{name.id}}"]
    end
    @@database = Kemalyst::Adapter::{{name.id.capitalize}}.new(settings)

    def self.database
      @@database
    end
  end  

  # sql_mapping is the mapping between columns in your database and the fields
  # in this model.  proerties will be created for each field.  The type of the
  # field is specific to the database you are using.  You may specify other
  # criteria for each field like `NOT NULL` and Referential Integrity. This
  # allows you to take full advantage of the database of choice.
  # you may also specify a specific table_name and if you want the timestamps
  # or not.  This will help with backward compatibility of existing databases.
  macro sql_mapping(fields, table_name = nil, timestamps = true)
    {% name_space = @type.name.downcase.id %}
    {% table_name = name_space + "s" unless table_name %}
    # Table Name
    @@table_name = "{{table_name}}"
    #Create the properties
    property id : (Int32 | Int64 | Nil)
    {% for name, types in fields %}
      property {{name.id}} : {{types[1].id}}?
    {% end %}
    {% if timestamps %}
    property created_at : Time?
    property updated_at : Time?
    {% end %}
   
    # Create the from_sql method
    def self.from_sql(result)
      model = {{@type.name.id}}.new
      
      # hack around different types for Pg and Mysql drivers
      unless model.id = result[0] as? Int32
        model.id = result[0] as? Int64
      end
      {% i = 1 %}
      {% for name, types in fields %}
        # Need to find a way to map to other types based on SQL type
        if result[{{i}}].class == Slice(UInt8) && {{types[1].id}} == String
          model.{{name.id}} = String.new ( result[{{i}}] as Slice(UInt8) )
        else
          model.{{name.id}} = result[{{i}}] as? {{types[1].id}}
        end
        {% i += 1 %}
      {% end %}

      {% if timestamps %}
        unless model.created_at = result[{{i}}] as? Time
          created_at_string = result[{{i}}] as? String
          if created_at_string
            model.created_at = Time::Format.new("%F %X").parse(created_at_string)
          end
        end
        unless model.updated_at = result[{{i + 1}}] as? Time
          updated_at_string = result[{{i + 1}}] as? String
          if updated_at_string
            model.updated_at = Time::Format.new("%F %X").parse(updated_at_string)
          end
        end
      {% end %}
      return model
    end

    # keep a hash of the fields to be used for mapping
    def self.fields(fields = {} of String => String)
        {% for name, types in fields %}
        fields["{{name.id}}"] = "{{types[0].id}}"
        {% end %}
        {% if timestamps %}
        fields["created_at"] = "TIMESTAMP"
        fields["updated_at"] = "TIMESTAMP"
        {% end %}
        return fields
    end

    # keep a hash of the params that will be passed to the adapter.
    def params
      return {
          {% for name, types in fields %}
            "{{name.id}}" => {{name.id}},
          {% end %}
          {% if timestamps %}
            "created_at" => created_at,
            "updated_at" => updated_at,
          {% end %}
      }
    end

  end #End of Fields Macro


  # Clear is used to remove all rows from the table and reset the counter for
  # the id.
  def self.clear
    if db = @@database
      db.clear(@@table_name)
    end
    return true
  end

  # Drop will drop the table completely.  This will lose data so be very
  # careful with this call.
  def self.drop
    if db = @@database
      db.drop(@@table_name)
    end
    return true
  end

  # Create will create the table for you based on the sql_mapping specified.
  def self.create
    if db = @@database
      db.create(@@table_name, fields)
    end
    return true
  end

  # Migrate will examine the current schema and additively update to match the
  # model.
  def self.migrate
    if db = @@database
      db.migrate(@@table_name, fields)
    end
    return true
  end

  # Prune fields no longer defined in the model.  This should be used after
  # you have successfully migrated.
  def self.prune
    if db = @@database
      db.prune(@@table_name, fields)
    end
    return true
  end

  # Perform a query directly against the database
  def self.query(statement : String, params = {} of String => String) 
    if db = @@database
      results = db.query(statement, params, fields)
    end
    return results
  end

  # The save method will check to see if the @id exists yet.  If it does it
  # will call the update method, otherwise it will call the create method.
  # This will update the timestamps apropriately.
  def save
    if db = @@database
      begin
        if value = @id
          updated_at = Time.now
          db.update(@@table_name, self.class.fields, value, params)
        else
          @created_at = Time.now
          @updated_at = Time.now
          @id = db.insert(@@table_name, self.class.fields, params)
        end
        return true
      rescue ex
        if message = ex.message
          errors << message
        end
        return false
      end
    else
      return false
    end
  end

  # Destroy will remove this from the database.
  def destroy
    if db = @@database
      begin
        db.delete(@@table_name, @id)
        return true
      rescue ex
        if message = ex.message
          errors << message
        end

        return false
      end
    else
      return false
    end
  end
  
  # All will return all rows in the database. The clause allows you to specify
  # a WHERE, JOIN, GROUP BY, ORDER BY and any other SQL92 compatible query to
  # your table.  The results will be an array of instantiated instances of
  # your Model class.  This allows you to take full advantage of the database
  # that you are using so you are not restricted or dummied down to support a
  # DSL.  
  def self.all(clause = "", params = {} of String => String)
    return self.select(@@table_name, fields({"id" => "INT"}), clause, params)
  end
  
  # find returns the row with the id specified.
  def self.find(id)
    return self.select_one(@@table_name, fields({"id" => "INT"}), id)
  end
  
  # select performs the select statement and calls the from_sql with the
  # results.
  def self.select(table_name, fields, clause, params = {} of String => String)
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

  # select_one is a convenience method for only returning the first instance of a
  # results.
  def self.select_one(table_name, fields, id)
    row = nil
    if db = @@database
      results = db.select_one(table_name, fields, id)
      if results.is_a?(Array)
        if results.size > 0
          row = self.from_sql(results.first)
        end
      end
    end
    return row
  end

end
