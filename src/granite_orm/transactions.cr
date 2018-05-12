module Granite::ORM::Transactions
  module ClassMethods
    def create(**args)
      create(args.to_h)
    end

    def create(args : Hash(Symbol | String, DB::Any))
      instance = new
      instance.set_attributes(args)
      instance.save
      instance
    end
  end

  macro __process_transactions
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}

    @updated_at : Time?
    @created_at : Time?

    # The import class method will run a batch INSERT statement for each model in the array
    # the array must contain only one model class
    # invalid model records will be skipped
    def self.import(model_array : Array(self), batch_size : Int32 = model_array.size)
      begin
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          @@adapter.import(table_name, primary_name, fields_duplicate, slice)
        end
      rescue err
        raise DB::Error.new(err.message)
      end
    end

    def self.import(model_array : Array(self), update_on_duplicate : Bool, columns : Array(String), batch_size : Int32 = model_array.size)
      begin
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          @@adapter.import(table_name, primary_name, fields_duplicate, slice)
        end
      rescue err
        raise DB::Error.new(err.message)
      end
    end

    def self.import(model_array : Array(self), ignore_on_duplicate : Bool, batch_size : Int32 = model_array.size)
      begin
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          @@adapter.import(table_name, primary_name, fields_duplicate, slice)
        end
      rescue err
        raise DB::Error.new(err.message)
      end
    end

    private def __create
      @created_at = @updated_at = Time.now.to_utc
      fields = self.class.content_fields.dup
      params = content_values
      if value = @{{primary_name}}
        fields << "{{primary_name}}"
        params << value
      end
      begin
        {% if primary_type.id == "Int32" %}
          @{{primary_name}} = @@adapter.insert(@@table_name, fields, params, lastval: true).to_i32
        {% elsif primary_type.id == "Int64" %}
          @{{primary_name}} = @@adapter.insert(@@table_name, fields, params, lastval: true)
        {% elsif primary_auto == true %}
          {% raise "Failed to define #{@type.name}#save: Primary key must be Int(32|64), or set `auto: false` for natural keys.\n\n  primary #{primary_name} : #{primary_type}, auto: false\n" %}
        {% else %}
          if @{{primary_name}}
            @@adapter.insert(@@table_name, fields, params, lastval: false)
          else
            message = "Primary key('{{primary_name}}') cannot be null"
            errors << Granite::ORM::Error.new("{{primary_name}}", message)
            raise DB::Error.new
          end
        {% end %}
      rescue err : DB::Error
        raise err
      rescue err
        raise DB::Error.new(err.message)
      end
      @new_record = false
    end

    private def __update
      @updated_at = Time.now.to_utc
      fields = self.class.content_fields
      params = content_values + [@{{primary_name}}]

      begin
        @@adapter.update @@table_name, @@primary_name, fields, params
      rescue err
        raise DB::Error.new(err.message)
      end
    end

    private def __destroy
      @@adapter.delete(@@table_name, @@primary_name, @{{primary_name}})
      @destroyed = true
    end

    # The save method will check to see if the primary exists yet. If it does it
    # will call the update method, otherwise it will call the create method.
    # This will update the timestamps appropriately.
    def save
      return false unless valid?

      begin
        if @{{primary_name}} && !new_record?
          __before_save
          __before_update
          __update
          __after_update
          __after_save
        else
          __before_save
          __before_create
          __create
          __after_create
          __after_save
        end
      rescue ex : DB::Error | Granite::ORM::Callbacks::Abort
        if message = ex.message
          Granite::ORM.settings.logger.error "Save Exception: #{message}"
          errors << Granite::ORM::Error.new(:base, message)
        end
        return false
      end
      true
    end

    # Destroy will remove this from the database.
    def destroy
      begin
        __before_destroy
        __destroy
        __after_destroy
      rescue ex : DB::Error | Granite::ORM::Callbacks::Abort
        if message = ex.message
          Granite::ORM.settings.logger.error "Destroy Exception: #{message}"
          errors << Granite::ORM::Error.new(:base, message)
        end
        return false
      end
      true
    end
  end

  # Returns true if this object hasn't been saved yet.
  getter? new_record : Bool = true

  # Returns true if this object has been destroyed.
  getter? destroyed : Bool = false

  # Returns true if the record is persisted.
  def persisted?
    !(new_record? || destroyed?)
  end
end
