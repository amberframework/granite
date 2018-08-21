require "./exceptions"

module Granite::Transactions
  module ClassMethods
    disable_granite_docs? def create(**args)
      create(args.to_h)
    end

    disable_granite_docs? def create(args : Hash(Symbol | String, DB::Any))
      instance = new
      instance.set_attributes(args)
      instance.save
      instance
    end

    disable_granite_docs? def create!(**args)
      create!(args.to_h)
    end

    disable_granite_docs? def create!(args : Hash(Symbol | String, DB::Any))
      instance = create(args)

      if instance.errors.any?
        raise Granite::RecordNotSaved.new(self.name, instance)
      end

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
    disable_granite_docs? def self.import(model_array : Array(self) | Granite::Collection(self), batch_size : Int32 = model_array.size)
      begin
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          @@adapter.import(table_name, primary_name, primary_auto, fields_duplicate, slice)
        end
      rescue err
        raise DB::Error.new(err.message)
      end
    end

    disable_granite_docs? def self.import(model_array : Array(self) | Granite::Collection(self), update_on_duplicate : Bool, columns : Array(String), batch_size : Int32 = model_array.size)
      begin
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          @@adapter.import(table_name, primary_name, primary_auto, fields_duplicate, slice, update_on_duplicate: update_on_duplicate, columns: columns)
        end
      rescue err
        raise DB::Error.new(err.message)
      end
    end

    disable_granite_docs? def self.import(model_array : Array(self) | Granite::Collection(self), ignore_on_duplicate : Bool, batch_size : Int32 = model_array.size)
      begin
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          @@adapter.import(table_name, primary_name, primary_auto, fields_duplicate, slice, ignore_on_duplicate: ignore_on_duplicate)
        end
      rescue err
        raise DB::Error.new(err.message)
      end
    end

    disable_granite_docs? def set_timestamps(*, to time = Time.now, mode = :create)
      if mode == :create
        @created_at = time.to_utc.at_beginning_of_second
      end

      @updated_at = time.to_utc.at_beginning_of_second
    end

    private def __create
      set_timestamps
      fields = self.class.content_fields.dup
      params = content_values
      if value = @{{primary_name}}
        fields << "{{primary_name}}"
        params << value
      end
      begin
        {% if primary_type.id == "Int32" %}
          @{{primary_name}} = @@adapter.insert(@@table_name, fields, params, lastval: "{{primary_name}}").to_i32
        {% elsif primary_type.id == "Int64" %}
          @{{primary_name}} = @@adapter.insert(@@table_name, fields, params, lastval: "{{primary_name}}")
        {% elsif primary_auto == true %}
          {% raise "Failed to define #{@type.name}#save: Primary key must be Int(32|64), or set `auto: false` for natural keys.\n\n  primary #{primary_name} : #{primary_type}, auto: false\n" %}
        {% else %}
          if @{{primary_name}}
            @@adapter.insert(@@table_name, fields, params, lastval: nil)
          else
            message = "Primary key('{{primary_name}}') cannot be null"
            errors << Granite::Error.new("{{primary_name}}", message)
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
      set_timestamps mode: :update
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
    disable_granite_docs? def save
      return false unless valid?

      begin
        __before_save
        if @{{primary_name}} && !new_record?
          __before_update
          __update
          __after_update
        else
          __before_create
          __create
          __after_create
        end
        __after_save
      rescue ex : DB::Error | Granite::Callbacks::Abort
        if message = ex.message
          Granite.settings.logger.error "Save Exception: #{message}"
          errors << Granite::Error.new(:base, message)
        end
        return false
      end
      true
    end


    disable_granite_docs? def save!
      save || raise Granite::RecordNotSaved.new(self.class.name, self)
    end

    disable_granite_docs? def update(**args)
      update(args.to_h)
    end

    disable_granite_docs? def update(args : Hash(Symbol | String, DB::Any))
      set_attributes(args)

      save
    end

    disable_granite_docs? def update!(**args)
      update!(args.to_h)
    end

    disable_granite_docs? def update!(args : Hash(Symbol | String, DB::Any))
      set_attributes(args)

      save!
    end

    # Destroy will remove this from the database.
    disable_granite_docs? def destroy
      begin
        __before_destroy
        __destroy
        __after_destroy
      rescue ex : DB::Error | Granite::Callbacks::Abort
        if message = ex.message
          Granite.settings.logger.error "Destroy Exception: #{message}"
          errors << Granite::Error.new(:base, message)
        end
        return false
      end
      true
    end

    disable_granite_docs? def destroy!
      destroy || raise Granite::RecordNotDestroyed.new(self.class.name, self)
    end
  end

  # Returns true if this object hasn't been saved yet.
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  getter? new_record : Bool = true

  # Returns true if this object has been destroyed.
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  getter? destroyed : Bool = false

  # Returns true if the record is persisted.
  disable_granite_docs? def persisted?
    !(new_record? || destroyed?)
  end
end
