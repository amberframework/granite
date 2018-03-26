module Granite::ORM::Transactions
  macro __process_transactions
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}

    @updated_at : Time?
    @created_at : Time?

    # The save method will check to see if the primary exists yet. If it does it
    # will call the update method, otherwise it will call the create method.
    # This will update the timestamps apropriately.
    def save
      return false unless valid?

      begin
        __run_before_save
        if value = @{{primary_name}}
          __run_before_update
          @updated_at = Time.now.to_utc
          params_and_pk = params
          params_and_pk << value
          @@adapter.update @@table_name, @@primary_name, self.class.fields, params_and_pk
          __run_after_update
        else
          __run_before_create
          @created_at = Time.now.to_utc
          @updated_at = Time.now.to_utc
          @{{primary_name}} = @@adapter.insert(@@table_name, @@primary_name, self.class.fields, params).as({{primary_type}})
          __run_after_create
        end
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
