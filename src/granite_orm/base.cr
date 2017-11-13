require "./associations"
require "./callbacks"
require "./fields"
require "./querying"
require "./settings"
require "./table"
require "./transactions"
require "./validators"
require "./version"

# Granite::ORM::Base is the base class for your model objects.
class Granite::ORM::Base
  include Associations
  include Callbacks
  include Fields
  include Table
  include Transactions
  include Validators

  extend Querying

  macro inherited
    macro finished
      __process_table
      __process_fields
      __process_querying
      __process_transactions
    end
  end

  def initialize(**args : Object)
    set_attributes(args.to_h)
  end

  def initialize(args : Hash(Symbol | String, String | JSON::Type))
    set_attributes(args)
  end

  def initialize
  end
end
