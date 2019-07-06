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
          self.\{{name.id}} = \{% if options[:converter] %} \{{options[:converter].id}}.from_rs result \{% else %} result.read(Union(\{{options[:type].id}} | Nil)) \{% end %}
          \{% if options[:type].id == "Time".id %}
            self.\{{name.id}} = self.\{{name.id}}.not_nil!.in(Granite.settings.default_timezone) if self.\{{name.id}}
          \{% end %}
        \{% end %}
        self
      end
    end
  end

  def raw_all(clause = "", params = [] of Granite::Fields::Type)
    rows = [] of self
    adapter.select(select_container, clause, params) do |results|
      results.each do
        rows << from_sql(results)
      end
    end
    rows
  end

  # All will return all rows in the database. The clause allows you to specify
  # a WHERE, JOIN, GROUP BY, ORDER BY and any other SQL92 compatible query to
  # your table. The result will be a Collection(Model) object which lazy loads
  # an array of instantiated instances of your Model class.
  # This allows you to take full advantage of the database
  # that you are using so you are not restricted or dummied down to support a
  # DSL.
  # Lazy load prevent running unnecessary queries from unused variables.
  def all(clause = "", params = [] of Granite::Fields::Type)
    Collection(self).new(->{ raw_all(clause, params) })
  end

  # First adds a `LIMIT 1` clause to the query and returns the first result
  def first(clause = "", params = [] of Granite::Fields::Type)
    all([clause.strip, "LIMIT 1"].join(" "), params).first?
  end

  def first!(clause = "", params = [] of Granite::Fields::Type)
    first(clause, params) || raise NotFound.new("No #{{{@type.name.stringify}}} found with first(#{clause})")
  end

  # find returns the row with the primary key specified. Otherwise nil.
  def find(value)
    first("WHERE #{primary_name} = ?", value)
  end

  # find returns the row with the primary key specified. Otherwise raises an exception.
  def find!(value)
    find(value) || raise Granite::Querying::NotFound.new("No #{{{@type.name.stringify}}} found where #{primary_name} = #{value}")
  end

  # Returns the first row found that matches *criteria*. Otherwise `nil`.
  def find_by(**criteria : Granite::Fields::Type)
    find_by criteria.to_h
  end

  # :ditto:
  def find_by(criteria : Hash(Symbol | String, Granite::Fields::Type))
    clause, params = build_find_by_clause(criteria)
    first "WHERE #{clause}", params
  end

  # Returns the first row found that matches *criteria*. Otherwise raises a `NotFound` exception.
  def find_by!(**criteria : Granite::Fields::Type)
    find_by!(criteria.to_h)
  end

  # :ditto:
  def find_by!(criteria : Hash(Symbol | String, Granite::Fields::Type))
    find_by(criteria) || raise NotFound.new("No #{{{@type.name.stringify}}} found where #{criteria.map { |k, v| %(#{k} #{v.nil? ? "is NULL" : "= #{v}"}) }.join(" and ")}")
  end

  def find_each(clause = "", params = [] of Granite::Fields::Type, batch_size limit = 100, offset = 0)
    find_in_batches(clause, params, batch_size: limit, offset: offset) do |batch|
      batch.each do |record|
        yield record
      end
    end
  end

  def find_in_batches(clause = "", params = [] of Granite::Fields::Type, batch_size limit = 100, offset = 0)
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

  # Returns `true` if a records exists with a PK of *id*, otherwise `false`.
  def exists?(id : Number | String | Nil) : Bool
    return false if id.nil?
    exec_exists "#{primary_name} = ?", [id]
  end

  # Returns `true` if a records exists that matches *criteria*, otherwise `false`.
  def exists?(**criteria : Granite::Fields::Type) : Bool
    exists? criteria.to_h
  end

  # :ditto:
  def exists?(criteria : Hash(Symbol | String, Granite::Fields::Type)) : Bool
    exec_exists *build_find_by_clause(criteria)
  end

  # count returns a count of all the records
  def count : Int32
    scalar "SELECT COUNT(*) FROM #{quoted_table_name}", &.to_s.to_i
  end

  def exec(clause = "")
    adapter.open { |db| db.exec(clause) }
  end

  def query(clause = "", params = [] of Granite::Fields::Type, &block)
    adapter.open { |db| yield db.query(clause, params) }
  end

  def scalar(clause = "", &block)
    adapter.open { |db| yield db.scalar(clause) }
  end

  private def exec_exists(clause : String, params : Array(Granite::Fields::Type)) : Bool
    adapter.exists? quoted_table_name, clause, params
  end

  private def build_find_by_clause(criteria : Hash(Symbol | String, Granite::Fields::Type))
    keys = criteria.keys
    criteria_hash = criteria.dup

    clauses = keys.map do |name|
      if criteria_hash[name]
        matcher = "= ?"
      else
        matcher = "IS NULL"
        criteria_hash.delete name
      end

      "#{quoted_table_name}.#{quote(name.to_s)} #{matcher}"
    end

    {clauses.join(" AND "), criteria_hash.values}
  end
end
