# Query runner which finalizes a query and runs it.
# This will likely require adapter specific subclassing :[.
class Query::Runner(T)
  def initialize(@query : Compiled(T), @adapter : Granite::Adapter::Base)
  end

  def log(*args)
    puts *args
  end

  def count : Int64
    sql = <<-SQL
    SELECT COUNT(*)
      FROM #{@query.table}
     WHERE #{@query.where}
    SQL

    log sql, @query.data
    count = 0_i64

    @adapter.open do |db|
      db.query_one sql, @query.data do |record_set|
        count = record_set.read Int64
      end
    end

    count
  end

  def first
    sql = <<-SQL
      SELECT
          #{@query.field_list}
        FROM #{@query.table}
       WHERE #{@query.where}
       LIMIT 1
    SQL

    log sql, @query.data
    results = [] of T

    @adapter.open do |db|
      db.query sql, @query.data do |record_set|
        record_set.each do
          results << T.from_sql record_set
        end
      end
    end

    results.first?
  end
end
