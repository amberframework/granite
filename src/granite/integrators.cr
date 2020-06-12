require "./transactions"
require "./querying_methods"

module Granite::Integrators
  include Transactions::ClassMethods
  include QueringMethods

  def find_or_create_by(**args)
    find_by(**args) || create(**args)
  end

  def find_or_initialize_by(**args)
    find_by(**args) || new(**args)
  end
end
