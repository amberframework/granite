module Granite
  abstract class Migration
    class Fields
      property connection : Granite::Adapter::Base
      property fields = Array(String).new

      def initialize(@connection : Granite::Adapter::Base)
      end

      def primary(name : Symbol)
        db_type = connection.class.schema_type?("Int64")
        fields << "#{name} #{db_type} PRIMARY KEY"
      end

      def serial(name : Symbol)
        db_type = connection.class.schema_type?("AUTO_Int32")
        fields << "#{name} #{db_type}"
      end

      def bigserial(name : Symbol)
        db_type = connection.class.schema_type?("AUTO_Int64")
        fields << "#{name} #{db_type}"
      end

      def uuid(name : Symbol)
        db_type = connection.class.schema_type?("UUID")
        fields << "#{name} #{db_type}"
      end

      def string(name : Symbol)
        db_type = connection.class.schema_type?("String")
        fields << "#{name} #{db_type}"
      end

      def text(name : Symbol)
        db_type = connection.class.schema_type?("String")
        fields << "#{name} #{db_type}"
      end

      def bool(name : Symbol)
        boolean(name)
      end

      def boolean(name : Symbol)
        db_type = connection.class.schema_type?("Bool")
        fields << "#{name} #{db_type}"
      end

      def reference(name : Symbol)
        bigint(name)
      end

      def int(name : Symbol)
        integer(name)
      end

      def integer(name : Symbol)
        db_type = connection.class.schema_type?("Int32")
        fields << "#{name} #{db_type}"
      end

      def bigint(name : Symbol)
        biginteger(name)
      end

      def biginteger(name : Symbol)
        db_type = connection.class.schema_type?("Int64")
        fields << "#{name} #{db_type}"
      end

      def float(name : Symbol)
        db_type = connection.class.schema_type?("Float32")
        fields << "#{name} #{db_type}"
      end

      def real(name : Symbol)
        db_type = connection.class.schema_type?("Float64")
        fields << "#{name} #{db_type}"
      end

      def time(name : Symbol)
        timestamp(name)
      end

      def timestamp(name : Symbol)
        db_type = connection.class.schema_type?("Time")
        fields << "#{name} #{db_type}"
      end

      def timestamps
        timestamp(:created_at)
        timestamp(:updated_at)
      end

      def custom(sql : String)
        fields << sql
      end

      def to_sql
        fields.join(", ")
      end
    end

    abstract def up
    abstract def down

    class_getter connection : Granite::Adapter::Base?
    property statements = Array(String).new

    def self.connection(name : Symbol)
      @@connection = Granite::Connections[name.to_s]
    end

    def execute(sql : String)
      statements << sql
    end

    def create_table(table : Symbol)
      statements << String.build do |ddl|
        fields = Fields.new(@@connection.not_nil!)
        yield fields

        ddl << "CREATE TABLE #{table} ("
        ddl << fields.to_sql
        ddl << ")"
      end
    end

    def rename_table
    end

    def drop_table(table : Symbol)
      statements << "DROP TABLE IF EXISTS \"#{table.to_s}\""
    end

    def create_index(table : Symbol, field : Symbol)
      create_index(table, [field])
    end

    def create_index(table : Symbol, fields : Array(Symbol))
      name = "#{table}-#{fields.join("-")}-idx"
      statements << "CREATE INDEX \"#{name.to_s}\" (#{fields.join(", ")})"
    end

    def drop_index(table : Symbol, field : Symbol)
      drop_index(table, [field])
    end

    def drop_index(table : Symbol, fields : Array(Symbol))
      name = "#{table}-#{fields.join("-")}-idx"
      statements << "DROP INDEX \"#{name.to_s}\""
    end

    def add_column
    end

    def rename_column
    end

    def remove_column
    end

    def add_foreign_key
    end

    def remove_foreign_key
    end

    def to_sql
      statements.join("; ") + ";"
    end
  end
end
