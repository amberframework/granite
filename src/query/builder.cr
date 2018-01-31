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

  # TODO maybe move this logic into the Runner(?)
  def build_where(parameter_count = 1) : { String, Array(FieldName), Array(FieldData) }
    data = [] of FieldData
    parameter_count += 1
    clause = @fields.map do |field, value|
      data << value
      "#{field} = $#{parameter_count}"
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
end
