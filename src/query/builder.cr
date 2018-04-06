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
class Query::Builder(Model)
  alias FieldName = String
  alias FieldData = DB::Any

  enum Sort
    Ascending
    Descending
  end

  getter where_fields
  getter order_fields

  def initialize(@boolean_operator = :and)
    @where_fields = {} of FieldName => FieldData
    @order_fields = [] of NamedTuple(field: String, direction: Sort)
  end

  def assembler
    # when adapter.postgresql?
    Assembler::Postgresql(Model).new self
    # when adapter.mysql?
    # etc
  end

  def where(**matches)
    matches.each do |field, data|
      @where_fields[field.to_s] = data
    end

    self
  end

  def order(field : Symbol)
    @order_fields << { field: field.to_s, direction: Sort::Ascending }

    self
  end

  def order(fields : Array(Symbol))
    fields.each do |field|
      order field
    end

    self
  end

  def order(**dsl)
    dsl.each do |field, dsl_direction|
      direction = Sort::Ascending

      if dsl_direction == "desc" || dsl_direction == :desc
        direction = Sort::Descending
      end

      @order_fields << { field: field.to_s, direction: direction }
    end

    self
  end

  def raw_sql
    assembler.select.raw_sql
  end

  def count : Executor::Value(Model, Int64)
    assembler.count
  end

  def first : Model?
    first(1).first?
  end

  def first(n : Int32) : Executor::List(Model)
    assembler.first(n)
  end

  def any? : Bool
    ! first.nil?
  end

  def delete
    assembler.delete
  end

  def select
    assembler.select.run
  end

  def size
    count
  end

  def reject(&block)
    assembler.select.run.reject do |record|
      yield record
    end
  end

  def each(&block)
    assembler.select.tap do |record_set|
      record_set.each do |record|
        yield record
      end
    end
  end

  def map(&block)
    assembler.select.run.map do |record|
      yield record
    end
  end
end
