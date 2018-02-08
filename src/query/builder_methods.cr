# DSL to be included into a model
# To activate, simply
#
# class Model < Granite::ORM::Base
#   include Query::BuilderMethods
# end
module Query::BuilderMethods
  def __builder
    Builder(self).new
  end

  def count : Executor(self, Int32)
    __builder.count
  end

  def where(**match_data) : Builder
    __builder.where **match_data
  end

  def first : self?
    __builder.first
  end

  def first(n : Int32) : Executor
    __builder.first n
  end
end
