module Granite::Query::Assembler
  abstract class Base(Model)
    @where : String?
    @order : String?
    @limit : String?
    @offset : String?
    @group_by : String?

    def initialize(@query : Builder(Model))
      @numbered_parameters = [] of DB::Any
      @aggregate_fields = [] of String
    end

    abstract def add_parameter(value : DB::Any) : String

    def numbered_parameters
      @numbered_parameters
    end

    def add_aggregate_field(name : String)
      @aggregate_fields << name
    end

    def table_name
      Model.table_name
    end

    def field_list
      [Model.fields].flatten.join ", "
    end

    def build_sql
      clauses = [] of String?
      yield clauses
      clauses.compact!.join " "
    end

    def where
      return @where if @where

      clauses = ["WHERE"]

      @query.where_fields.each do |expression|
        add_aggregate_field expression[:field]

        clauses << expression[:join].to_s.upcase unless clauses.size == 1

        if expression[:value].nil?
          clauses << "#{expression[:field]} IS NULL"
        else
          clauses << "#{expression[:field]} #{sql_operator(expression[:operator])} #{add_parameter expression[:value]}"
        end
      end

      return nil if clauses.size == 1

      @where = clauses.join(" ")
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

    def limit
      @limit ||= if limit = @query.limit
                   "LIMIT #{limit}"
                 end
    end

    def offset
      @offset ||= if offset = @query.offset
                    "OFFSET #{offset}"
                  end
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
        s << where
        s << group_by
        s << order(use_default_order: false)
      end

      Executor::Value(Model, Int64).new sql, numbered_parameters, default: 0_i64
    end

    def first(n : Int32 = 1) : Executor::List(Model)
      sql = build_sql do |s|
        s << "SELECT #{field_list}"
        s << "FROM #{table_name}"
        s << where
        s << order
        s << "LIMIT #{n}"
        s << offset
      end

      Executor::List(Model).new sql, numbered_parameters
    end

    def delete
      sql = build_sql do |s|
        s << "DELETE FROM #{table_name}"
        s << where
      end

      log sql, numbered_parameters
      Model.adapter.open do |db|
        db.exec sql, numbered_parameters
      end
    end

    def aggregate(query : String, t : T.class) forall T
      sql = build_sql do |s|
        s << "SELECT #{query}"
        s << "FROM #{table_name}"
        s << where
        s << group_by
        s << order(use_default_order: false)
      end
      Executor::Value(Model, T).new sql, numbered_parameters, default: 0
    end

    def select
      sql = build_sql do |s|
        s << "SELECT #{field_list}"
        s << "FROM #{table_name}"
        s << where
        s << order
        s << limit
        s << offset
      end

      Executor::List(Model).new sql, numbered_parameters
    end

    OPERATORS = {"eq": "=", "gteq": ">=", "lteq": "<=", "neq": "!=", "ltgt": "<>", "gt": ">", "lt": "<", "ngt": "!>", "nlt": "!<", "in": "IN", "nin": "NOT IN", "like": "LIKE", "nlike": "NOT LIKE"}

    def sql_operator(operator : Symbol) : String
      OPERATORS[operator.to_s]? || operator.to_s
    end
  end
end
