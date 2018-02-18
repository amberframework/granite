module Granite::ORM::Querying
  class NotFound < Exception
  end  

  macro extended
    macro __process_querying
      \{% primary_name = PRIMARY[:name] %}
      \{% primary_type = PRIMARY[:type] %}

      # Create the from_sql method
      def self.from_sql(result)
        model = \{{@type.name.id}}.new

        model.\{{primary_name}} = result.read(\{{primary_type}})

        \{% for name, type in FIELDS %}
          model.\{{name.id}} = result.read(Union(\{{type.id}} | Nil))
        \{% end %}

        \{% if SETTINGS[:timestamps] %}
          model.created_at = result.read(Union(Time | Nil))
          model.updated_at = result.read(Union(Time | Nil))
        \{% end %}
        return model
      end
    end
  end

  # Clear is used to remove all rows from the table and reset the counter for
  # the primary key.
  def clear
    @@adapter.clear @@table_name
  end

  # All will return all rows in the database. The clause allows you to specify
  # a WHERE, JOIN, GROUP BY, ORDER BY and any other SQL92 compatible query to
  # your table.  The results will be an array of instantiated instances of
  # your Model class.  This allows you to take full advantage of the database
  # that you are using so you are not restricted or dummied down to support a
  # DSL.
  def all(clause = "", params = [] of DB::Any)
    rows = [] of self
    @@adapter.select(@@table_name, fields([@@primary_name]), clause, params) do |results|
      results.each do
        rows << from_sql(results)
      end
    end
    return rows
  end

  # First adds a `LIMIT 1` clause to the query and returns the first result
  def first?(clause = "", params = [] of DB::Any)
    all([clause.strip, "LIMIT 1"].join(" "), params).first?
  end

  def first(clause = "", params = [] of DB::Any)
    first?(clause, params) || raise NotFound.new("Couldn't find " + {{@type.name.stringify}} + " with first(#{clause})")
  end

  # find returns the row with the primary key specified.
  # it checks by primary by default, but one can pass
  # another field for comparison
  def find?(value)
    return find_by?(@@primary_name, value)
  end

  def find(value)
    return find_by(@@primary_name, value)
  end

  # find_by returns the first row found where the field maches the value
  def find_by?(field : String | Symbol, value)
    row = nil
    @@adapter.select_one(@@table_name, fields([@@primary_name]), field.to_s, value) do |result|
      row = from_sql(result) if result
    end
    return row
  end

  def find_by(field : String | Symbol, value)
    find_by?(field, value) || raise NotFound.new("Couldn't find " + {{@type.name.stringify}} + " with #{field}=#{value}")
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

    while true
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
