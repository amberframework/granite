require "yaml"
require "db"

# Kemalyst::Model is the base class for your model objects.
class Kemalyst::Model
  VERSION = "0.2.0"
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
    @@adapter = Kemalyst::Adapter::{{name.id.capitalize}}.new(settings)

    def self.adapter
      @@adapter
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
    property id : Int64?
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

      model.id = result.read(Int64)

      {% for name, types in fields %}
        model.{{name.id}} = result.read(Union({{types[1].id}} | Nil))
      {% end %}

      {% if timestamps %}
        formatter = Time::Format.new("%F %X")
        model.created_at = formatter.parse(result.read(String))
        model.updated_at = formatter.parse(result.read(String))
      {% end %}
      return model
    end

    # keep a hash of the fields to be used for mapping
    def self.fields(fields = {} of String => String)
        {% for name, types in fields %}
        fields["{{name.id}}"] = "{{types[0].id}}"
        {% end %}
        {% if timestamps %}
        fields["created_at"] = "VARCHAR(255)"
        fields["updated_at"] = "VARCHAR(255)"
        {% end %}
        return fields
    end

    # keep a hash of the params that will be passed to the adapter.
    def params
      params = [] of DB::Any
      {% for name, types in fields %}
        params << {{name.id}}
      {% end %}
      {% if timestamps %}
        formatter = Time::Format.new("%F %X")
        if time = created_at
          params << formatter.format(time)
        else
          params << nil
        end
        if time = updated_at
          params << formatter.format(time)
        else
          params << nil
        end
      {% end %}
      return params
   end
  end #End of Fields Macro

  # Clear is used to remove all rows from the table and reset the counter for
  # the id.
  def self.clear
    @@adapter.clear @@table_name
  end

  # Drop will drop the table completely.  This will lose data so be very
  # careful with this call.
  def self.drop
    @@adapter.drop @@table_name
  end

  # Create will create the table for you based on the sql_mapping specified.
  def self.create
    @@adapter.create @@table_name, fields
  end

  # Migrate will examine the current schema and additively update to match the
  # model.
  def self.migrate
    @@adapter.migrate @@table_name, fields
  end

  # # Prune fields no longer defined in the model.  This should be used after
  # # you have successfully migrated.
  def self.prune
    @@adapter.prune @@table_name, fields
  end

  # The save method will check to see if the @id exists yet.  If it does it
  # will call the update method, otherwise it will call the create method.
  # This will update the timestamps apropriately.
  def save
    begin
      if value = @id
        @updated_at = Time.now
        params_and_id = params
        params_and_id << value
        @@adapter.update @@table_name, self.class.fields, params_and_id 
      else
        @created_at = Time.now
        @updated_at = Time.now
        @id = @@adapter.insert @@table_name, self.class.fields, params
      end
      return true
    rescue ex
      if message = ex.message
        puts "Save Exception: #{message}"
        errors << message
      end
      return false
    end
  end

  # Destroy will remove this from the database.
  def destroy
    begin
      @@adapter.delete(@@table_name, id)
      return true
    rescue ex
      if message = ex.message
        puts "Destroy Exception: #{message}"
        errors << message
      end
      return false
    end
  end

  # All will return all rows in the database. The clause allows you to specify
  # a WHERE, JOIN, GROUP BY, ORDER BY and any other SQL92 compatible query to
  # your table.  The results will be an array of instantiated instances of
  # your Model class.  This allows you to take full advantage of the database
  # that you are using so you are not restricted or dummied down to support a
  # DSL.
  def self.all(clause = "", params = [] of DB::Any)
    rows = [] of self
    @@adapter.select(@@table_name, fields({"id" => "BIGINT"}), clause, params) do |results|
      results.each do
        rows << self.from_sql(results)
      end
    end
    return rows
  end

  # find returns the row with the id specified.
  def self.find(id)
    row = nil
    @@adapter.select_one(@@table_name, fields({"id" => "BIGINT"}), id) do |result|
      row = self.from_sql(result) if result
    end
    return row
  end

  def self.exec(clause = "")
    @@adapter.open {|db| db.exec(clause) }
  end

  def self.query(clause = "", params = [] of DB::Any, &block)
    @@adapter.open {|db| yield db.query(clause, params) }
  end

  def self.scalar(clause = "", &block)
    @@adapter.open {|db| yield db.scalar(clause) }
  end
end
