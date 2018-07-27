require "./collection"
require "./association_collection"
require "./associations"
require "./callbacks"
require "./fields"
require "./querying"
require "./settings"
require "./table"
require "./transactions"
require "./validators"
require "./validation_helpers"
require "./migrator"
require "./select"
require "./version"
require "./adapters"

# Granite::Base is the base class for your model objects.
class Granite::Base
  include Associations
  include Callbacks
  include Fields
  include Table
  include Transactions
  include Validators
  include ValidationHelpers
  include Migrator
  include Select

  include JSON::Serializable
  include YAML::Serializable

  extend Querying
  extend Transactions::ClassMethods

  macro inherited
    macro finished
      __process_table
      __process_fields
      __process_select
      __process_querying
      __process_transactions
      __process_migrator
    end
  end

  def initialize(**args : Object)
    set_attributes(args.to_h)
  end

  def initialize(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)
  end

  def initialize
  end
end
