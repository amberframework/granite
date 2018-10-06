# Query runner which finalizes a query and runs it.
# This will likely require adapter specific subclassing :[.
module Granite::Query::Assembler
  class Postgresql(Model) < Base(Model)
    @where : String?
    @order : String?
    @group_by : String?

    def where
      return @where if @where

      clauses = @query.where_fields.map do |field, value|
        add_aggregate_field field

        # TODO value is an array
        if value.nil?
          "#{field} IS NULL"
        else
          "#{field} = #{add_parameter value}"
        end
      end

      return nil if clauses.none?

      @where = "WHERE #{clauses.join " AND "}"
    end

    def order(use_default_order = true)
      return @order if @order

      order_fields = @query.order_fields

      if order_fields.none?
        if use_default_order
          order_fields = default_order
        else
          return nil
        end
      end

      order_clauses = order_fields.map do |expression|
        add_aggregate_field expression[:field]

        if expression[:direction] == Builder::Sort::Ascending
          "#{expression[:field]} ASC"
        else
          "#{expression[:field]} DESC"
        end
      end

      @order = "ORDER BY #{order_clauses.join ", "}"
    end

    def log(*stuff)
    end

    def default_order
      [{field: Model.primary_name, direction: "ASC"}]
    end

    def group_by
      @group_by ||= if @aggregate_fields.any?
                      "GROUP BY #{@aggregate_fields.join ", "}"
                    end
    end

    def count : Executor::Value(Model, Int64)
      sql = build_sql do |s|
        s << "SELECT COUNT(*)"
        s << "FROM #{table_name}"
        s << where if where
        s << group_by if group_by
        s << order if order
      end

      Executor::Value(Model, Int64).new sql, numbered_parameters, default: 0_i64
    end

    def first(n : Int32 = 1) : Executor::List(Model)
      sql = build_sql do |s|
        s << "SELECT #{field_list}"
        s << "FROM #{table_name}"
        s << where if where
        s << order if order
        s << "LIMIT #{n}"
      end

      Executor::List(Model).new sql, numbered_parameters
    end

    def delete
      sql = build_sql do |s|
        s << "DELETE FROM #{table_name}"
        s << where if where
      end

      log sql, numbered_parameters
      Model.adapter.open do |db|
        db.exec sql, numbered_parameters
      end
    end

    def select
      sql = build_sql do |s|
        s << "SELECT #{field_list}"
        s << "FROM #{table_name}"
        s << where if where
        s << order if order
      end

      Executor::List(Model).new sql, numbered_parameters
    end
  end
end
