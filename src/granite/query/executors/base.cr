module Granite::Query::Executor
  module Shared
    def raw_sql : String
      @sql
    end

    def log(*messages)
      if logger = Granite.settings.logger
        messages.each { |message| logger.info message }
      end
    end
  end
end
