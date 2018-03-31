module Granite::ORM::Transactions
  macro __process_transactions
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}

    @updated_at : Time?
    @created_at : Time?

    # The save method will check to see if the primary exists yet. If it does it
    # will call the update method, otherwise it will call the create method.
    # This will update the timestamps apropriately.
    def save
      return false unless valid?

      begin
        __run_before_save
        now = Time.now.to_utc

        if (value = @{{primary_name}}) && !new_record?
          __run_before_update
          @updated_at = now
          fields = self.class.content_fields
          params = content_values + [value]

          begin
            @@adapter.update @@table_name, @@primary_name, fields, params
          rescue err
            raise DB::Error.new(err.message)
          end
          __run_after_update
        else
          __run_before_create
          @created_at = @updated_at = now
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
          __run_after_create
        end
        @new_record = false
        __run_after_save
        return true
      rescue ex : DB::Error
        if message = ex.message
          Granite::ORM.settings.logger.error "Save Exception: #{message}"
          errors << Granite::ORM::Error.new(:base, message)
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
        @destroyed = true
        return true
      rescue ex : DB::Error
        if message = ex.message
          Granite::ORM.settings.logger.error "Destroy Exception: #{message}"
          errors << Granite::ORM::Error.new(:base, message)
        end
        return false
      end
    end
  end

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

  # Returns true if this object hasn't been saved yet.
  getter? new_record : Bool = true

  # Returns true if this object has been destroyed.
  getter? destroyed : Bool = false

  # Returns true if the record is persisted.
  def persisted?
    !(new_record? || destroyed?)
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
