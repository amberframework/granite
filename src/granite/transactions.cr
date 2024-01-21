require "./exceptions"

module Granite::Transactions
  module ClassMethods
    # Removes all records from a table.
    def clear
      adapter.clear table_name
    end

    # Creates a new record, and attempts to save it to the database. Returns the
    # newly created record.
    #
    # **NOTE**: This method still outputs the new object even when it failed to save
    # to the database. The only way to determine a failure is to check any errors on
    # the object, or to use `#create!`.
    def create(**args)
      create(args.to_h)
    end

    # Creates a new record, and attempts to save it to the database. Allows saving
    # the record without timestamps. Returns the newly created record.
    def create(args, skip_timestamps : Bool = false)
      instance = new
      instance.set_attributes(args.to_h.transform_keys(&.to_s))
      instance.save(skip_timestamps: skip_timestamps)
      instance
    end

    # Creates a new record, and attempts to save it to the database. Returns the
    # newly created record. Raises `Granite::RecordNotSaved` if the save is
    # unsuccessful.
    def create!(**args)
      create!(args.to_h)
    end

    # Creates a new record, and attempts to save it to the database. Allows saving
    # the record without timestamps. Returns the newly created record. Raises
    # `Granite::RecordNotSaved` if the save is unsuccessful.
    def create!(args, skip_timestamps : Bool = false)
      instance = create(args, skip_timestamps)

      unless instance.errors.empty?
        raise Granite::RecordNotSaved.new(self.name, instance)
      end

      instance
    end

    # Runs an INSERT statement for all records in *model_array*.
    # the array must contain only one model class
    # invalid model records will be skipped
    def import(model_array : Array(self) | Granite::Collection(self), batch_size : Int32 = model_array.size)
      {% begin %}
        {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
        {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
        {% ann = primary_key.annotation(Granite::Column) %}
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          slice.each do |i|
            i.before_save
            i.before_create
          end
          adapter.import(table_name, {{primary_key.name.stringify}}, {{ann[:auto]}}, fields_duplicate, slice)
          slice.each do |i|
            i.after_create
            i.after_save
          end
        end
      {% end %}
    rescue err
      raise DB::Error.new(err.message, cause: err)
    end

    # Runs an INSERT statement for all records in *model_array*, with options to
    # update any duplicate records, and provide column names.
    def import(model_array : Array(self) | Granite::Collection(self), update_on_duplicate : Bool, columns : Array(String), batch_size : Int32 = model_array.size)
      {% begin %}
        {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
        {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
        {% ann = primary_key.annotation(Granite::Column) %}
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          slice.each do |i|
            i.before_save
            i.before_create
          end
          adapter.import(table_name, {{primary_key.name.stringify}}, {{ann[:auto]}}, fields_duplicate, slice, update_on_duplicate: update_on_duplicate, columns: columns)
          slice.each do |i|
            i.after_create
            i.after_save
          end
        end
      {% end %}
    rescue err
      raise DB::Error.new(err.message, cause: err)
    end

    def import(model_array : Array(self) | Granite::Collection(self), ignore_on_duplicate : Bool, batch_size : Int32 = model_array.size)
      {% begin %}
        {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
        {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
        {% ann = primary_key.annotation(Granite::Column) %}
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          slice.each do |i|
            i.before_save
            i.before_create
          end
          adapter.import(table_name, {{primary_key.name.stringify}}, {{ann[:auto]}}, fields_duplicate, slice, ignore_on_duplicate: ignore_on_duplicate)
          slice.each do |i|
            i.after_create
            i.after_save
          end
        end
      {% end %}
    rescue err
      raise DB::Error.new(err.message, cause: err)
    end
  end

  # Sets the record's timestamps(created_at & updated_at) to the current time.
  def set_timestamps(*, to time = Time.local(Granite.settings.default_timezone), mode = :create)
    {% if @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) && ivar.type == Time? }.map(&.name.stringify).includes? "created_at" %}
      if mode == :create
        @created_at = time.at_beginning_of_second
      end
    {% end %}

    {% if @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) && ivar.type == Time? }.map(&.name.stringify).includes? "updated_at" %}
      @updated_at = time.at_beginning_of_second
    {% end %}
  end

  private def __create(skip_timestamps : Bool = false)
    {% begin %}
      {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
      {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
      {% raise "Composite primary keys are not yet supported for '#{@type.name}'." if @type.instance_vars.select { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] }.size > 1 %}
      {% ann = primary_key.annotation(Granite::Column) %}

      set_timestamps unless skip_timestamps
      fields = self.class.content_fields.dup
      params = content_values

      if value = @{{primary_key.name.id}}
        fields << {{primary_key.name.stringify}}
        params << value
      end

      {% if primary_key.type == Int32? && ann[:auto] == true %}
        @{{primary_key.name.id}} = self.class.adapter.insert(self.class.table_name, fields, params, lastval: {{primary_key.name.stringify}}).to_i32
      {% elsif primary_key.type == Int64? && ann[:auto] == true %}
        @{{primary_key.name.id}} = self.class.adapter.insert(self.class.table_name, fields, params, lastval: {{primary_key.name.stringify}})
      {% elsif primary_key.type == UUID? && ann[:auto] == true %}
          # if the primary key has not been set, then do so

          unless fields.includes?({{primary_key.name.stringify}})
            _uuid = UUID.random
            @{{primary_key.name.id}} = _uuid
            params << _uuid
            fields << {{primary_key.name.stringify}}
          end
          self.class.adapter.insert(self.class.table_name, fields, params, lastval: nil)
      {% elsif ann[:auto] == true %}
        {% raise "Failed to define #{@type.name}#save: Primary key must be Int(32|64) or UUID, or set `auto: false` for natural keys.\n\n  column #{primary_key.name} : #{primary_key.type}, primary: true, auto: false\n" %}
      {% else %}
        if @{{primary_key.name.id}}
          self.class.adapter.insert(self.class.table_name, fields, params, lastval: nil)
        else
          message = "Primary key('{{primary_key.name}}') cannot be null"
          errors << Granite::Error.new({{primary_key.name.stringify}}, message)
          raise DB::Error.new
        end
      {% end %}
    {% end %}
  rescue err : DB::Error
    raise err
  rescue err
    raise DB::Error.new(err.message, cause: err)
  else
    self.new_record = false
  end

  private def __update(skip_timestamps : Bool = false)
    {% begin %}
    {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
    {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
    {% ann = primary_key.annotation(Granite::Column) %}
    set_timestamps(mode: :update) unless skip_timestamps
    fields = self.class.content_fields.dup
    params = content_values + [@{{primary_key.name.id}}]

    # Do not update created_at on update
    if created_at_index = fields.index("created_at")
      fields.delete_at created_at_index
      params.delete_at created_at_index
    end

    begin
     self.class.adapter.update(self.class.table_name, self.class.primary_name, fields, params)
    rescue err
      raise DB::Error.new(err.message, cause: err)
    end
  {% end %}
  end

  private def __destroy
    {% begin %}
    {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
    {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
    {% ann = primary_key.annotation(Granite::Column) %}
    self.class.adapter.delete(self.class.table_name, self.class.primary_name, @{{primary_key.name.id}})
    @destroyed = true
  {% end %}
  end

  # Attempts to save the record to the database, returning `true` if successful,
  # and `false` if not. If the save is unsuccessful, `#errors` will be populated
  # with the errors which caused the save to fail.
  #
  # **NOTE**: This method can be used both on new records, and existing records.
  # In the case of new records, it creates the record in the database, otherwise,
  # it updates the record in the database.
  def save(*, validate : Bool = true, skip_timestamps : Bool = false)
    {% begin %}
    {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
    {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
    {% ann = primary_key.annotation(Granite::Column) %}
    return false if validate && !valid?

    begin
      __before_save
      if @{{primary_key.name.id}} && !new_record?
        __before_update
        __update(skip_timestamps: skip_timestamps)
        __after_update
      else
        __before_create
        __create(skip_timestamps: skip_timestamps)
        __after_create
      end
      __after_save
    rescue ex : DB::Error | Granite::Callbacks::Abort
      if message = ex.message
        Log.error { "Save Exception: #{message}" }
        errors << Granite::Error.new(:base, message)
      end
      return false
    end
    true
  {% end %}
  end

  # Same as `#save`, but raises `Granite::RecordNotSaved` if the save is unsuccessful.
  def save!(*, validate : Bool = true, skip_timestamps : Bool = false)
    save(validate: validate, skip_timestamps: skip_timestamps) || raise Granite::RecordNotSaved.new(self.class.name, self)
  end

  # Updates the record with the new data specified by *args*. Returns `true` if the
  # update is successful, `false` if it isn't.
  def update(**args)
    update(args.to_h)
  end

  # Updates the record with the new data specified by *args*, with the option to
  # not update timestamps. Returns `true` if the update is successful, `false` if
  # it isn't.
  def update(args, skip_timestamps : Bool = false)
    set_attributes(args.to_h.transform_keys(&.to_s))

    save(skip_timestamps: skip_timestamps)
  end

  # Updates the record with the new data specified by *args*. Raises
  # `Granite::RecordNotSaved` if the save is unsuccessful.
  def update!(**args)
    update!(args.to_h)
  end

  # Updates the record with the new data specified by *args*, with the option to
  # not update timestamps. Raises `Granite::RecordNotSaved` if the save is
  # unsuccessful.
  def update!(args, skip_timestamps : Bool = false)
    set_attributes(args.to_h.transform_keys(&.to_s))

    save!(skip_timestamps: skip_timestamps)
  end

  # Removes the record from the database. Returns `true` if successful, `false`
  # otherwise.
  def destroy
    begin
      __before_destroy
      __destroy
      __after_destroy
    rescue ex : DB::Error | Granite::Callbacks::Abort
      if message = ex.message
        Log.error { "Destroy Exception: #{message}" }
        errors << Granite::Error.new(:base, message)
      end
      return false
    end
    true
  end

  # Same as `#destroy`, but raises `Granite::RecordNotDestroyed` if unsuccessful.
  def destroy!
    destroy || raise Granite::RecordNotDestroyed.new(self.class.name, self)
  end

  # Updates the *updated_at* field to the current time, without saving other fields.
  #
  # Raises error if record hasn't been saved to the database yet.
  def touch(*fields) : Bool
    raise "Cannot touch on a new record object" unless persisted?
    {% begin %}
      fields.each do |field|
        case field.to_s
          {% for time_field in @type.instance_vars.select { |ivar| ivar.type == Time? } %}
            when {{time_field.stringify}} then @{{time_field.id}} = Time.local(Granite.settings.default_timezone).at_beginning_of_second
          {% end %}
        else
          if {{@type.instance_vars.map(&.name.stringify)}}.includes? field.to_s
            raise "{{@type.name}}.#{field} cannot be touched.  It is not of type `Time`."
          else
            raise "Field '#{field}' does not exist on type '{{@type.name}}'."
          end
        end
      end
    {% end %}
    set_timestamps mode: :update
    save
  end
end
