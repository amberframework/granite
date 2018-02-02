# Data structure which will allow chaining of query components,
# nesting of boolean logic, etc.
#
# Should return self, or another instance of Builder wherever
# chaining should be possible.
#
# Current query syntax:
# - where(field: value) => "WHERE field = 'value'"
#
# Hopefully soon:
# - Model.where(field: value).not( Model.where(field2: value2) )
# or
# - Model.where(field: value).not { where(field2: value2) }
#
# - Model.where(field: value).or( Model.where(field3: value3) )
# or
# - Model.where(field: value).or { whehre(field3: value3) }
class Query::Builder(T)
  alias FieldName = String
  alias FieldData = DB::Any

  def initialize(@boolean_operator = :and)
    @fields = {} of FieldName => FieldData
    @order  = [] of NamedTuple(field: String, direction: String)
  end

  def compile
    Compiled(T).new self
  end

  def runner
    Runner(T).new compile
  end

  def where(**matches)
    matches.each do |field, data|
      @fields[field.to_s] = data
    end

    self
  end

  def order(field : Symbol)
    @order << { field: field, direction: :ascending }

    self
  end

  def order(**dsl)
    dsl.each do |field, dsl_direction|
      direction = "ASC"

      if dsl_direction == "desc" || dsl_direction == :desc
        direction = "DESC"
      end

      @order << { field: field.to_s, direction: direction }
    end

    self
  end

  def _build_order
    if @order.none?
      default_order
    end

    @order.map do |expression|
      "#{expression[:field]} #{expression[:direction]}"
    end.join ", "
  end

  def default_order
    @order = [{ field: T.primary_name, direction: "ASC" }]
  end

  # TODO maybe move this logic into the Runner(?)
  def _build_where(parameter_count = 1) : { String, Array(FieldName), Array(FieldData) }
    data = [] of FieldData
    clause = @fields.map do |field, value|
      data << value
      "#{field} = $#{parameter_count}".tap do
        parameter_count += 1
      end
    end.join " AND "

    { clause, T.fields, data }
  end

  def count : Int64
    runner.count
  end

  def first : T?
    first(1).first?
  end

  def first(n : Int32) : Array(T)
    runner.first(n)
  end

  def any? : Bool
    ! first.nil?
  end

  def delete
    runner.delete
  end
end
