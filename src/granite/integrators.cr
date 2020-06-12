require "./transactions"

module Granite::Integrators
  include Transactions::ClassMethods
  include QueryingMethods

  def find_or_create_by(**args)
    find_by(**args) || create(**args)
  end

  def find_or_initialize_by(**args)
    find_by(**args) || new(**args)
  end
end
