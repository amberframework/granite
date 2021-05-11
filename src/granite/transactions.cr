require "./exceptions"

module Granite::Transactions
  module ClassMethods
    def clear
      adapter.clear table_name
    end

    def create(**args)
      create(args.to_h)
    end

    def create(args : Granite::ModelArgs)
      instance = new
      instance.set_attributes(args.transform_keys(&.to_s))
      instance.save
      instance
    end

    def create!(**args)
      create!(args.to_h)
    end

    def create!(args : Granite::ModelArgs)
      instance = create(args)

      if instance.errors.any?
        raise Granite::RecordNotSaved.new(self.name, instance)
      end

      instance
    end

    # The import class method will run a batch INSERT statement for each model in the array
    # the array must contain only one model class
    # invalid model records will be skipped
    def import(model_array : Array(self) | Granite::Collection(self), batch_size : Int32 = model_array.size)
      {% begin %}
        {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
        {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
        {% ann = primary_key.annotation(Granite::Column) %}
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          adapter.import(table_name, {{primary_key.name.stringify}}, {{ann[:auto]}}, fields_duplicate, slice)
        end
      {% end %}
    rescue err
      raise DB::Error.new(err.message)
    end

    def import(model_array : Array(self) | Granite::Collection(self), update_on_duplicate : Bool, columns : Array(String), batch_size : Int32 = model_array.size)
      {% begin %}
        {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
        {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
        {% ann = primary_key.annotation(Granite::Column) %}
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          adapter.import(table_name, {{primary_key.name.stringify}}, {{ann[:auto]}}, fields_duplicate, slice, update_on_duplicate: update_on_duplicate, columns: columns)
        end
      {% end %}
    rescue err
      raise DB::Error.new(err.message)
    end

    def import(model_array : Array(self) | Granite::Collection(self), ignore_on_duplicate : Bool, batch_size : Int32 = model_array.size)
      {% begin %}
        {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
        {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
        {% ann = primary_key.annotation(Granite::Column) %}
        fields_duplicate = fields.dup
        model_array.each_slice(batch_size, true) do |slice|
          adapter.import(table_name, {{primary_key.name.stringify}}, {{ann[:auto]}}, fields_duplicate, slice, ignore_on_duplicate: ignore_on_duplicate)
        end
      {% end %}
    rescue err
      raise DB::Error.new(err.message)
    end
  end

  def set_timestamps(*, to time = Time.local(Granite.settings.default_timezone), mode = :create)
    {% if @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.name.stringify).includes? "created_at" %}
      if mode == :create
        @created_at = time.at_beginning_of_second
      end
    {% end %}

    {% if @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.name.stringify).includes? "updated_at" %}
      @updated_at = time.at_beginning_of_second
    {% end %}
  end

  private def __create
    {% begin %}
      {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
      {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
      {% raise "Composite primary keys are not yet supported for '#{@type.name}'." if @type.instance_vars.select { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] }.size > 1 %}
      {% ann = primary_key.annotation(Granite::Column) %}

      set_timestamps
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
          _uuid = UUID.random
          @{{primary_key.name.id}} = _uuid
          params << _uuid
          fields << {{primary_key.name.stringify}}
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
    raise DB::Error.new(err.message)
  else
    self.new_record = false
  end

  private def __update
    {% begin %}
    {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
    {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
    {% ann = primary_key.annotation(Granite::Column) %}
    set_timestamps mode: :update
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
      raise DB::Error.new(err.message)
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

  # The save method will check to see if the primary key exists yet. If it does
  # it will call the update method, otherwise it will call the create method.
  # This will update the timestamps appropriately.
  def save(*, validate : Bool = true)
    {% begin %}
    {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
    {% raise raise "A primary key must be defined for #{@type.name}." unless primary_key %}
    {% ann = primary_key.annotation(Granite::Column) %}
    return false if validate && !valid?

    begin
      __before_save
      if @{{primary_key.name.id}} && !new_record?
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
        Log.error { "Save Exception: #{message}" }
        errors << Granite::Error.new(:base, message)
      end
      return false
    end
    true
  {% end %}
  end

  def save!(*, validate : Bool = true)
    save(validate: validate) || raise Granite::RecordNotSaved.new(self.class.name, self)
  end

  def update(**args)
    update(args.to_h)
  end

  def update(args : Granite::ModelArgs)
    set_attributes(args.transform_keys(&.to_s))

    save
  end

  def update!(**args)
    update!(args.to_h)
  end

  def update!(args : Granite::ModelArgs)
    set_attributes(args.transform_keys(&.to_s))

    save!
  end

  # Destroy will remove this from the database.
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

  def destroy!
    destroy || raise Granite::RecordNotDestroyed.new(self.class.name, self)
  end

  # Saves the record with the *updated_at*/*names* fields updated to the current time.
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
    @updated_at = Time.local(Granite.settings.default_timezone).at_beginning_of_second
    save
  end
end
