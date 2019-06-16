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

  extend Querying
  extend Query::BuilderMethods
  extend Transactions::ClassMethods
  extend Integrators

  macro inherited
    include JSON::Serializable
    include YAML::Serializable
    macro finished
      __process_table
      __process_fields
      __process_select
      __process_querying
      __process_transactions
      __process_migrator
    end

    def initialize(**args : Granite::Fields::Type)
      set_attributes(args.to_h)
    end

    def initialize(args : Hash(Symbol | String, Granite::Fields::Type))
      set_attributes(args)
    end

    def initialize
    end
  end
end
