module Query::Executor
  class List(Model)
    include Shared

    def initialize(@sql : String, @args = [] of DB::Any)
    end

    def run : Array(Model)
      log @sql, @args

      results = [] of Model

      Model.adapter.open do |db|
        db.query @sql, @args do |record_set|
          record_set.each do
            results << Model.from_sql record_set
          end
        end
      end

      results
    end

    delegate :[], :first?, :first, :each, :group_by, to: :run
    delegate :to_s, to: :run
  end
end
