module Granite::ORM::Querying
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
  def first(clause = "", params = [] of DB::Any)
    all([clause.strip, "LIMIT 1"].join(" "), params).first?
  end

  # find returns the row with the primary key specified.
  # it checks by primary by default, but one can pass
  # another field for comparison
  def find(value)
    return find_by(@@primary_name, value)
  end

  # find_by using symbol for field name.
  def find_by(field : Symbol, value)
    find_by(field.to_s, value)
  end

  # find_by returns the first row found where the field maches the value
  def find_by(field : String, value)
    row = nil
    @@adapter.select_one(@@table_name, fields([@@primary_name]), field, value) do |result|
      row = from_sql(result) if result
    end
    return row
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

  def create(**args)
    create(args.to_h)
  end

  def create(args : Hash(Symbol | String, DB::Any))
    instance = new
    instance.set_attributes(args)
    instance.save
    instance
  end
end
