require "./callbacks"
require "./fields"
require "./querying"
require "./version"

# Granite::ORM::Base is the base class for your model objects.
class Granite::ORM::Base
  include Callbacks
  include Fields

  extend Querying

  macro inherited
    include Kemalyst::Validators

    PRIMARY = {name: id, type: Int64}

    macro finished
      __process
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

  macro __process
    {% name_space = @type.name.gsub(/::/, "_").downcase.id %}
    {% table_name = SETTINGS[:table_name] || name_space + "s" %}
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    # Table Name
    @@table_name = "{{table_name}}"
    @@primary_name = "{{primary_name}}"
    # Create the primary key
    property {{primary_name}} : Union({{primary_type.id}} | Nil)

    __process_fields
    __process_querying

    # The save method will check to see if the primary exists yet. If it does it
    # will call the update method, otherwise it will call the create method.
    # This will update the timestamps apropriately.
    def save
      begin
        __run_before_save
        if value = @{{primary_name}}
          __run_before_update
          @updated_at = Time.now
          params_and_pk = params
          params_and_pk << value
          @@adapter.update @@table_name, @@primary_name, self.class.fields, params_and_pk
          __run_after_update
        else
          __run_before_create
          @created_at = Time.now
          @updated_at = Time.now
          {% if primary_type.id == "Int32" %}
            @{{primary_name}} = @@adapter.insert(@@table_name, self.class.fields, params).to_i32
          {% else %}
            @{{primary_name}} = @@adapter.insert(@@table_name, self.class.fields, params)
          {% end %}
          __run_after_create
        end
        __run_after_save
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
        __run_before_destroy
        @@adapter.delete(@@table_name, @@primary_name, {{primary_name}})
        __run_after_destroy
        return true
      rescue ex
        if message = ex.message
          puts "Destroy Exception: #{message}"
          errors << Kemalyst::Validators::Error.new(:base, message)
        end
        return false
      end
    end
  end # End of Fields Macro

  def initialize(**args : Object)
    set_attributes(args.to_h)
  end

  def initialize(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)
  end

  def initialize
  end
end
