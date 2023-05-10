require "./collection"
require "./association_collection"
require "./associations"
require "./callbacks"
require "./columns"
require "./query/executors/base"
require "./query/**"
require "./settings"
require "./table"
require "./validators"
require "./validation_helpers/**"
require "./migrator"
require "./select"
require "./version"
require "./connections"
require "./integrators"
require "./converters"
require "./type"

# Granite::Base is the base class for your model objects.
abstract class Granite::Base
  include Associations
  include Callbacks
  include Columns
  include Tables
  include Transactions
  include Validators
  include ValidationHelpers
  include Migrator
  include Select

  extend Columns::ClassMethods
  extend Tables::ClassMethods
  extend Granite::Migrator::ClassMethods

  extend Querying
  extend Query::BuilderMethods
  extend Transactions::ClassMethods
  extend Integrators
  extend Select

  @@last_write_time = Time.monotonic
  @@current_adapter : Granite::Adapter::Base?

  def self.last_write_time
    @@last_write_time
  end

  # This is done this way because callbacks don't work on class mthods
  def self.update_last_write_time
    @@last_write_time = Time.monotonic
  end

  def update_last_write_time
    self.class.update_last_write_time
  end

  def self.time_since_last_write
    Time.monotonic - @@last_write_time
  end

  def time_since_last_write
    self.class.time_since_last_write
  end

  def self.switch_to_reader_adapter
    if time_since_last_write > 2.seconds
      @@current_adapter = @@reader_adapter
    end
  end

  def switch_to_reader_adapter
    self.class.switch_to_reader_adapter
  end

  def self.switch_to_writer_adapter
    @@current_adapter = @@writer_adapter
  end

  def switch_to_writer_adapter
    self.class.switch_to_writer_adapter
  end

  def self.schedule_adapter_switch
    spawn do
      sleep 2.seconds
      switch_to_reader_adapter
    end
  end

  def schedule_adapter_switch
    self.class.schedule_adapter_switch
  end

  def self.adapter
    begin
      @@current_adapter.not_nil!
    rescue NilAssertionError
      Granite::Connections.registered_connections.first?.not_nil![:writer]
    end
  end

  macro inherited
    protected class_getter select_container : Container = Container.new(table_name: table_name, fields: fields)

    include JSON::Serializable
    include YAML::Serializable

    # Returns true if this object hasn't been saved yet.
    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    disable_granite_docs? property? new_record : Bool = true

    # Returns true if this object has been destroyed.
    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    disable_granite_docs? getter? destroyed : Bool = false

    # Returns true if the record is persisted.
    disable_granite_docs? def persisted?
      !(new_record? || destroyed?)
    end

    disable_granite_docs? def initialize(**args : Granite::Columns::Type)
      set_attributes(args.to_h.transform_keys(&.to_s))
    end

    disable_granite_docs? def initialize(args : Granite::ModelArgs)
      set_attributes(args.transform_keys(&.to_s))
    end

    disable_granite_docs? def initialize
    end

    before_save :switch_to_writer_adapter
    before_destroy :switch_to_writer_adapter
    after_save :update_last_write_time
    after_save :schedule_adapter_switch
    after_destroy :update_last_write_time
    after_destroy :schedule_adapter_switch
  end
end
