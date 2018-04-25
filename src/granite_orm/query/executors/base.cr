module Granite::Query::Executor
  module Shared
    def raw_sql : String
      @sql
    end

    def log(*messages)
      Granite::Logger.log messages
    end
  end
end
