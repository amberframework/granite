# Query runner which finalizes a query and runs it.
# This will likely require adapter specific subclassing :[.
module Query::Assembler
  class Postgresql(Model) < Base(Model)
    def build_where
      clauses = @query.where_fields.map do |field, value|
        add_aggregate_field field

        # TODO value is an array
        if value.nil?
          "#{field} IS NULL"
        else
          "#{field} = #{add_parameter value}"
        end
      end

      return "" if clauses.none?

      "WHERE #{clauses.join " AND "}"
    end

    def build_order(use_default_order = true)
      order_fields = @query.order_fields

      if order_fields.none?
        if use_default_order
          order_fields = default_order
        else
          return ""
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

      "ORDER BY #{order_clauses.join ", "}"
    end

    def log(*stuff)
    end

    def default_order
      [{ field: Model.primary_name, direction: "ASC" }]
    end

    def build_group_by
      if @aggregate_fields.any?
        "GROUP BY #{@aggregate_fields.join ", "}"
      else
        ""
      end
    end

    def count : Executor::Value(Model, Int64)
      where = build_where
      order = build_order(use_default_order = false)
      group = build_group_by

      sql = <<-SQL
        SELECT COUNT(*)
          FROM #{table_name}
         #{where}
         #{group}
         #{order}
      SQL

      Executor::Value(Model, Int64).new sql, numbered_parameters, default: 0_i64
    end

    def first(n : Int32 = 1) : Executor::List(Model)
      sql = <<-SQL
          SELECT #{field_list}
            FROM #{table_name}
           #{build_where}
           #{build_order}
           LIMIT #{n}
      SQL

      Executor::List(Model).new sql, numbered_parameters
    end

    def delete
      sql = <<-SQL
         DELETE
           FROM #{table_name}
          #{build_where}
      SQL

      log sql, numbered_parameters
      Model.adapter.open do |db|
        db.exec sql, numbered_parameters
      end
    end

    def select
      sql = <<-SQL
        SELECT #{field_list}
          FROM #{table_name}
          #{build_where}
          #{build_order}
      SQL

      Executor::List(Model).new sql, numbered_parameters
    end
  end
end
