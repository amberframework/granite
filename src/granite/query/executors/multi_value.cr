module Granite::Query::Executor
  class MultiValue(Model, Scalar)
    include Shared

    def initialize(@sql : String, @args = [] of Granite::Fields::Type, @default : Scalar = nil)
    end

    def run : Array(Scalar)
      log @sql, @args

      raise "No default provided" if @default.nil?
      results = [] of Scalar

      Model.adapter.open do |db|
        db.query @sql, @args do |record_set|
          record_set.each do
            results << record_set.read(Scalar)
          end
        end
      end

      results
    end

    delegate :<, :>, :<=, :>=, to: :run
    delegate :to_i, :to_s, to: :run
  end
end
