class FakeStatement < DB::Statement
  protected def perform_query(args : Enumerable) : DB::ResultSet
    FieldEmitter.new
  end

  protected def perform_exec(args : Enumerable) : DB::ExecResult
    DB::ExecResult.new 0_i64, 0_i64
  end
end

class FakeContext
  include DB::ConnectionContext

  def uri : URI
    URI.new ""
  end

  def prepared_statements? : Bool
    false
  end

  def discard(connection); end

  def release(connection); end
end

class FakeConnection < DB::Connection
  def initialize
    @context = FakeContext.new
    @prepared_statements = false
  end

  def build_unprepared_statement(query) : FakeStatement
    FakeStatement.new self, query
  end

  def build_prepared_statement(query) : FakeStatement
    FakeStatement.new self, query
  end
end

alias EmitterType = DB::Any | PG::Numeric | JSON::Any | Int16

# FieldEmitter emulates the subtle and uninformed way that
# DB::ResultSet emits data. To be used in testing interactions
# with raw data sets.
class FieldEmitter < DB::ResultSet
  # 1. Override `#move_next` to move to the next row.
  # 2. Override `#read` returning the next value in the row.
  # 3. (Optional) Override `#read(t)` for some types `t` for which custom logic other than a simple cast is needed.
  # 4. Override `#column_count`, `#column_name`.

  @position = 0
  @field_position = 0
  @values = [] of EmitterType

  def initialize
    @statement = FakeStatement.new FakeConnection.new, ""
  end

  def _set_values(values : Array(EmitterType))
    @values = [] of EmitterType
    values.each do |v|
      @values << v
    end
  end

  def move_next : Bool
    @position += 1
    @field_position = 0
    @position < @values.size
  end

  def read
    if @position >= @values.size
      raise "Overread"
    end

    @values[@position].tap do
      @position += 1
    end
  end

  def column_count : Int32
    @values.size
  end

  def column_name(index : Int32) : String
    "Column #{index}"
  end
end
