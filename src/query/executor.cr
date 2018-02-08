class Query::Executor(T,K)
  enum Method
    One
    Query
    Exec
    Value
  end

  def self.query(sql : String, args = [] of DB::Any)
    new Method::Query, sql, args
  end

  def self.value(sql : String, args = [] of DB::Any)
    new Method::Value, sql, args
  end

  def initialize(@execute_as : Method, @query : String, @args = [] of DB::Any)
  end

  def log(*args)
    puts
    puts *args
    puts
  end


  def run
    case @execute_as
    when Method::Value
      run_value
    when Method::Query
      run_query
    else
      raise "oops"
    end
  end

  def run_value
    log @query, @args
    # db.scalar raises when a query returns 0 results, so I'm using query_one?
    # https://github.com/crystal-lang/crystal-db/blob/7d30e9f50e478cb6404d16d2ce91e639b6f9c476/src/db/statement.cr#L18
    T.adapter.open do |db|
      db.query_one? @query, @args do |record_set|
        return record_set.read.as K
      end
    end
  end

  def run_query
    log @query, @args

    results = [] of T

    T.adapter.open do |db|
      db.query @query, @args do |record_set|
        record_set.each do
          results << T.from_sql record_set
        end
      end
    end

    results
  end

  def raw_sql
    @query
  end

  def as_array
    raise "#{K} is not arrayish" unless K == Array(T)
    run_query.as Array(T)
  end

  def as_number
    raise "#{K} is not numberish" unless K == Int32
    run_value.as K
  end

  delegate :[], :first?, :first, :each, to: :as_array
  delegate :<, :>, :<=, :>=, to: :as_number
end
