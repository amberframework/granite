module Query::Executor
  class Value(Model, Scalar)
    include Shared

    def initialize(@sql : String, @args = [] of DB::Any, @default : Scalar = nil)
    end

    def run : Scalar
      log @sql, @args
      # db.scalar raises when a query returns 0 results, so I'm using query_one?
      # https://github.com/crystal-lang/crystal-db/blob/7d30e9f50e478cb6404d16d2ce91e639b6f9c476/src/db/statement.cr#L18

      raise "No default provided" unless @default

      Model.adapter.open do |db|
        db.query_one? @sql, @args do |record_set|
          return record_set.read.as Scalar
        end
      end

      @default.not_nil!
    end

    delegate :<, :>, :<=, :>=, to: :run
    delegate :to_s, to: :run
  end
end
