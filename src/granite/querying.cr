module Granite::Querying
  class NotFound < Exception
  end

  macro extended
    macro __process_querying
      \{% primary_name = PRIMARY[:name] %}
      \{% primary_type = PRIMARY[:type] %}

      # Create the from_sql method
      disable_granite_docs? def self.from_sql(result)
        model = \{{@type.name.id}}.new
        model.set_attributes(result)
        model
      end

      disable_granite_docs? def set_attributes(result : DB::ResultSet)
        # Loading from DB means existing records.
        @new_record = false
        \{% for name, options in FIELDS %}
          self.\{{name.id}} = result.read(Union(\{{options[:type].id}} | Nil))
        \{% end %}
        self
      end
    end
  end

  # Clear is used to remove all rows from the table and reset the counter for
  # the primary key.
  def clear
    @@adapter.clear @@table_name
  end

  def raw_all(clause = "", params = [] of DB::Any)
    rows = [] of self
    @@adapter.select(@@select, clause, params) do |results|
      results.each do
        rows << from_sql(results)
      end
    end
    return rows
  end

  # All will return all rows in the database. The clause allows you to specify
  # a WHERE, JOIN, GROUP BY, ORDER BY and any other SQL92 compatible query to
  # your table. The result will be a Collection(Model) object which lazy loads
  # an array of instantiated instances of your Model class.
  # This allows you to take full advantage of the database
  # that you are using so you are not restricted or dummied down to support a
  # DSL.
  # Lazy load prevent running unnecessary queries from unused variables.
  def all(clause = "", params = [] of DB::Any)
    Collection(self).new(->{ raw_all(clause, params) })
  end

  # First adds a `LIMIT 1` clause to the query and returns the first result
  def first(clause = "", params = [] of DB::Any)
    all([clause.strip, "LIMIT 1"].join(" "), params).first?
  end

  def first!(clause = "", params = [] of DB::Any)
    first(clause, params) || raise NotFound.new("No #{{{@type.name.stringify}}} found with first(#{clause})")
  end

  # find returns the row with the primary key specified. Otherwise nil.
  def find(value)
    first("WHERE #{@@primary_name} = ?", value)
  end

  # find returns the row with the primary key specified. Otherwise raises an exception.
  def find!(value)
    find(value) || raise Granite::Querying::NotFound.new("No #{{{@type.name.stringify}}} found where #{@@primary_name} = #{value}")
  end

  # find_by returns the first row found that matches the given criteria. Otherwise nil.
  def find_by(**args)
    first("WHERE #{args.map { |name| "#{quote(@@table_name)}.#{quote(name.to_s)} = ?" }.join(" AND ")}", args.values.to_a)
  end

  # find_by returns the first row found that matches the given criteria. Otherwise raises an exception.
  def find_by!(**args)
    find_by(**args) || raise NotFound.new("No #{{{@type.name.stringify}}} found where #{args.map { |k, v| "#{k} = #{v}" }.join(" and ")}")
  end

  def find_each(clause = "", params = [] of DB::Any, batch_size limit = 100, offset = 0)
    find_in_batches(clause, params, batch_size: limit, offset: offset) do |batch|
      batch.each do |record|
        yield record
      end
    end
  end

  def find_in_batches(clause = "", params = [] of DB::Any, batch_size limit = 100, offset = 0)
    if limit < 1
      raise ArgumentError.new("batch_size must be >= 1")
    end

    loop do
      results = all "#{clause} LIMIT ? OFFSET ?", params + [limit, offset]
      break unless results.any?
      yield results
      offset += limit
    end
  end

  # count returns a count of all the records
  def count : Int32
    scalar "SELECT COUNT(*) FROM #{quoted_table_name}", &.to_s.to_i
  end

  def exec(clause = "")
    @@adapter.open { |db| db.exec(clause) }
  end

  def query(clause = "", params = [] of DB::Any, &block)
    @@adapter.open { |db| yield db.query(clause, params) }
  end

  def scalar(clause = "", &block)
    @@adapter.open { |db| yield db.scalar(clause) }
  end
end
