require "yaml"
require "db"
require "kemalyst-validators"

# Granite::ORM is the base class for your model objects.
class Granite::ORM
  macro inherited
    include Kemalyst::Validators

    PRIMARY = {name: id, type: Int64}
    FIELDS = {} of Nil => Nil
    SETTINGS = {} of Nil => Nil

    macro finished
      process_fields
    end
  end

  # specify the database adapter you will be using for this model.
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    @@adapter = Granite::Adapter::{{name.id.capitalize}}.new("{{name.id}}")

    def self.adapter
      @@adapter
    end
  end

  # specify the table name to use otherwise it will use the model's name
  macro table_name(name)
    {% SETTINGS[:table_name] = name.id %}
  end

  # specify the primary key column and type
  macro primary(decl)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
  end

  # specify the fields you want to define and types
  macro field(decl)
    {% FIELDS[decl.var] = decl.type %}
  end

  # include created_at and updated_at that will automatically be updated
  macro timestamps
    {% SETTINGS[:timestamps] = true %}
  end

  macro process_fields
    {% name_space = @type.name.gsub(/::/, "_").downcase.id %}
    {% table_name = SETTINGS[:table_name] || name_space + "s" %}
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    # Table Name
    @@table_name = "{{table_name}}"
    @@primary_name = "{{primary_name}}"
    #Create the properties
    property {{primary_name}} : Union({{primary_type.id}} | Nil)
    {% for name, type in FIELDS %}
      property {{name.id}} : Union({{type.id}} | Nil)
    {% end %}
    {% if SETTINGS[:timestamps] %}
    property created_at : Time?
    property updated_at : Time?
    {% end %}

    # Create the from_sql method
    def self.from_sql(result)
      model = {{@type.name.id}}.new

      model.{{primary_name}} = result.read({{primary_type}})

      {% for name, type in FIELDS %}
        model.{{name.id}} = result.read(Union({{type.id}} | Nil))
      {% end %}

      {% if SETTINGS[:timestamps] %}
        model.created_at = result.read(Union(Time | Nil))
        model.updated_at = result.read(Union(Time | Nil))
      {% end %}
      return model
    end

    # keep a hash of the fields to be used for mapping
    def self.fields(fields = [] of String)
        {% for name, type in FIELDS %}
        fields << "{{name.id}}"
        {% end %}
        {% if SETTINGS[:timestamps] %}
        fields << "created_at"
        fields << "updated_at"
        {% end %}
        return fields
    end

    # Cast params and set fields.
    private def cast_to_field(name, value : DB::Any)
      case name.to_s
      {% for _name, type in FIELDS %}
      when "{{_name.id}}"
        {% if type.id == Int32.id %}
          @{{_name.id}} = value.to_i32
        {% elsif type.id == Int64.id %}
          @{{_name.id}} = value.to_i64
        {% elsif type.id == Float32.id %}
          @{{_name.id}} = value.to_f32{0.0}
        {% elsif type.id == Float64.id %}
          @{{_name.id}} = value.to_f64{0.0}
        {% elsif type.id == Bool.id %}
          @{{_name.id}} = ["1", "yes", "true", true].includes?(value)
        {% elsif type.id == Time.id %}
          if value.is_a?(Time)
            @{{_name.id}} = value
          elsif value.to_s =~ /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/
            @{{_name.id}} = Time.parse(value, "%F %X")
          end
        {% else %}
          @{{_name.id}} = value.to_s
        {% end %}
      {% end %}
      end
    end

    # keep a hash of the params that will be passed to the adapter.
    def params
      params = [] of DB::Any
      {% for name, type in FIELDS %}
        params << {{name.id}}
      {% end %}
      {% if SETTINGS[:timestamps] %}
        params << created_at.not_nil!.to_s("%F %X")
        params << updated_at.not_nil!.to_s("%F %X")
      {% end %}
      return params
    end

    # Clear is used to remove all rows from the table and reset the counter for
    # the primary key.
    def self.clear
      @@adapter.clear @@table_name
    end

    # The save method will check to see if the primary exists yet. If it does it
    # will call the update method, otherwise it will call the create method.
    # This will update the timestamps apropriately.
    def save
      begin
        if value = @{{primary_name}}
          @updated_at = Time.now
          params_and_pk = params
          params_and_pk << value
          @@adapter.update @@table_name, @@primary_name, self.class.fields, params_and_pk
        else
          @created_at = Time.now
          @updated_at = Time.now
          {% if primary_type.id == "Int32" %}
            @{{primary_name}} = @@adapter.insert(@@table_name, self.class.fields, params).to_i32
          {% else %}
            @{{primary_name}} = @@adapter.insert(@@table_name, self.class.fields, params)
          {% end %}
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
        @@adapter.delete(@@table_name, @@primary_name, {{primary_name}})
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
      @@adapter.select(@@table_name, fields([@@primary_name]), clause, params) do |results|
        results.each do
          rows << self.from_sql(results)
        end
      end
      return rows
    end

    # find returns the row with the primary key specified.
    # it checks by primary by default, but one can pass
    # another field for comparison
    def self.find(value)
      return self.find_by(@@primary_name, value)
    end

    # find_by using symbol for field name.
    def self.find_by(field : Symbol, value)
      self.find_by(field.to_s, value)
    end

    # find_by returns the first row found where the field maches the value
    def self.find_by(field : String, value)
      row = nil
      @@adapter.select_one(@@table_name, fields([@@primary_name]), field, value) do |result|
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
  end # End of Fields Macro

  def set_attributes(args : Hash(Symbol | String, DB::Any))
    args.each do |k, v|
      cast_to_field(k, v)
    end
  end

  def set_attributes(**args)
    set_attributes(args.to_h)
  end

  def initialize(**args : Object)
    set_attributes(args.to_h)
  end

  def initialize(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)
  end

  def initialize
  end

  def self.create(**args)
    self.create(args.to_h)
  end

  def self.create(args : Hash(Symbol | String, DB::Any)) 
    instance = new
    instance.set_attributes(args)
    instance.save
    instance
  end
end
