# Represents all the parts of a SQL command
class Query::Compiled(T)
  getter table
  getter where
  getter limit
  getter order

  getter data

  @table : String
  @primary_key : String

  def initialize(@builder : Builder(T))
    @primary_key = T.primary_name
    @table = T.table_name
    @where = ""
    @limit = ""
    @order = ""
    @data  = [] of Builder::FieldData
    @fields = [] of Builder::FieldName

    build_where
    build_limit
    build_order
  end

  private def build_where
    parameter_count = 1
    @where, fields, data = @builder._build_where(parameter_count)
    parameter_count += data.size
    @fields += fields
    @data += data

    # Something like a visitor is due here for nested where clauses...
    # builder = @builder
    # while builder.next_clause?
    #   @where, fields = builder.next_clause parameter_count
    #   @data += fields
    #   parameter_count += data.size
    #   if builder.next_clause?
    #     builder = builder.next_clause
    #   else
    #     break
    #   end
    # end
  end

  def field_list
    [@primary_key, @fields].flatten.join ", "
  end

  def where?
    ! @where.blank?
  end

  private def build_limit
  end

  def limit?
    ! @limit.blank?
  end

  private def build_order
    @order = @builder._build_order
  end

  def order?
    ! @order.blank?
  end

  def where
    if where?
      @where
    else
      "true"
    end
  end
end
