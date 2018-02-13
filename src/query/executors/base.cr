module Query::Executor
  module Shared
    def raw_sql : String
      @sql
    end

    def log(*stuff)
      puts
      puts *stuff
      puts
    end
  end
end
