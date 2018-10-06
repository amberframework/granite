# DSL to be extended into a model
# To activate, simply
#
# class Model < Granite::Base
#   extend Query::BuilderMethods
# end
module Granite::Query::BuilderMethods
  def __builder
    Builder(self).new
  end

  delegate where, count, order, offset, limit, first, to: __builder
end
