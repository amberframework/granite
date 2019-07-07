require "./collection"
require "./association_collection"
require "./associations"
require "./callbacks"
require "./fields"
require "./query/executors/base"
require "./query/**"
require "./settings"
require "./table"
require "./validators"
require "./validation_helpers/**"
require "./migrator"
require "./select"
require "./version"
require "./adapters"
require "./integrators"
require "./converters"
require "./type"

# Granite::Base is the base class for your model objects.
abstract class Granite::Base
  include Associations
  include Callbacks
  include Fields
  include Table
  include Transactions
  include Validators
  include ValidationHelpers
  include Migrator
  include Select

  extend Fields::ClassMethods
  extend Table::ClassMethods
  extend Granite::Migrator::ClassMethods

  extend Querying
  extend Query::BuilderMethods
  extend Transactions::ClassMethods
  extend Integrators

  macro inherited
    include JSON::Serializable
    include YAML::Serializable

    @@select = Container.new(table_name: table_name, fields: fields)

    def self.select_container : Container
      @@select
    end

    # Returns true if this object hasn't been saved yet.
    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    property? new_record : Bool = true

    # Returns true if this object has been destroyed.
    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    getter? destroyed : Bool = false

    # Returns true if the record is persisted.
    disable_granite_docs? def persisted?
      !(new_record? || destroyed?)
    end

    def initialize(**args : Granite::Fields::Type)
      set_attributes(args.to_h.transform_keys(&.to_s))
    end

    def initialize(args : Hash(Symbol | String, Granite::Fields::Type))
      set_attributes(args.transform_keys(&.to_s))
    end

    def initialize
    end
  end
end
