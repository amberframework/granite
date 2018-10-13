# DSL to be extended into a model
# To activate, simply
#
# class Model < Granite::Base
#   extend Query::BuilderMethods
# end
module Granite::Query::BuilderMethods
  def __builder
    db_type = case adapter.class
              when Granite::Adapter::Pg
                Granite::Query::Builder::DbType::Pg
              when Granite::Adapter::Mysql
                Granite::Query::Builder::DbType::Mysql
              when Granite::Adapter::Sqlite
                Granite::Query::Builder::DbType::Sqlite
              else
                raise "Adapter not supported #{adapter.class}"
              end

    Builder(self).new(db_type)
  end

  delegate where, count, order, offset, limit, first, to: __builder
end
