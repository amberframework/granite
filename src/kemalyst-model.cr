require "yaml"
require "db"
require "kemalyst-validators"

# Kemalyst::Model is the base class for your model objects.
class Kemalyst::Model
  macro inherited
    include Kemalyst::Validators
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
    {% for name, type in fields %}
      property {{name.id}} : {{type.id}}?
    {% end %}
    {% if timestamps %}
    property created_at : Time?
    property updated_at : Time?
    {% end %}

    # Create the from_sql method
    def self.from_sql(result)
      model = {{@type.name.id}}.new

      model.id = result.read(Int64)

      {% for name, type in fields %}
        model.{{name.id}} = result.read(Union({{type.id}} | Nil))
      {% end %}

      {% if timestamps %}
        model.created_at = result.read(Union(Time | Nil))
        model.updated_at = result.read(Union(Time | Nil))
      {% end %}
      return model
    end

    # keep a hash of the fields to be used for mapping
    def self.fields(fields = [] of String)
        {% for name, type in fields %}
        fields << "{{name.id}}"
        {% end %}
        {% if timestamps %}
        fields << "created_at"
        fields << "updated_at"
        {% end %}
        return fields
    end

    # keep a hash of the params that will be passed to the adapter.
    def params
      params = [] of DB::Any
      {% for name, type in fields %}
        params << {{name.id}}
      {% end %}
      {% if timestamps %}
        params << created_at.not_nil!.to_s("%F %X")
        params << updated_at.not_nil!.to_s("%F %X")
      {% end %}
      return params
   end
  end # End of Fields Macro

  # Clear is used to remove all rows from the table and reset the counter for
  # the id.
  def self.clear
    @@adapter.clear @@table_name
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
        errors << Kemalyst::Validators::Error.new(:base, message)
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
        errors << Kemalyst::Validators::Error.new(:base, message)
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
    @@adapter.select(@@table_name, fields(["id"]), clause, params) do |results|
      results.each do
        rows << self.from_sql(results)
      end
    end
    return rows
  end

  # find returns the row with the id specified.
  # it checks by id by default, but one can pass
  # another field for comparison
  def self.find(id)
    return self.find_by("id", id)
  end

  # find_by using symbol for field name.
  def self.find_by(field : Symbol, value)
    self.find_by(field.to_s, value)
  end

  # find_by returns the first row found where the field maches the value
  def self.find_by(field : String, value)
    row = nil
    @@adapter.select_one(@@table_name, fields(["id"]), field, value) do |result|
      row = self.from_sql(result) if result
    end
    return row
  end

  def self.exec(clause = "")
    @@adapter.open { |db| db.exec(clause) }
  end

  def self.query(clause = "", params = [] of DB::Any, &block)
    @@adapter.open { |db| yield db.query(clause, params) }
  end

  def self.scalar(clause = "", &block)
    @@adapter.open { |db| yield db.scalar(clause) }
  end
end
