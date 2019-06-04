require "./transactions"
require "./querying"
module Granite::Integrators
  include Transactions::ClassMethods
  include Querying

  def find_or_create_by(**args)
    find_by(**args) || create(**args)
  end
end