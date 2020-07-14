module Granite
  abstract class Migration
    class Fields
      CRYSTAL_TYPES = {
        "serial"     => "AUTO_Int32",
        "bigserial"  => "AUTO_Int64",
        "uuid"       => "UUID",
        "string"     => "String",
        "text"       => "String",
        "bool"       => "Bool",
        "boolean"    => "Bool",
        "reference"  => "Int64",
        "int"        => "Int32",
        "integer"    => "Int32",
        "bigint"     => "Int64",
        "biginteger" => "Int64",
        "float"      => "Float32",
        "real"       => "Float64",
        "time"       => "Time",
        "timestamp"  => "Time",
      }

      property connection : Granite::Adapter::Base
      property fields = Array(String).new

      def initialize(@connection : Granite::Adapter::Base)
      end

      def primary(name : Symbol)
        db_type = convert_type_to_db_type(:bigserial)
        fields << "#{name} #{db_type} PRIMARY KEY"
      end

      def serial(name : Symbol)
        db_type = convert_type_to_db_type(:serial)
        fields << "#{name} #{db_type}"
      end

      def bigserial(name : Symbol)
        db_type = convert_type_to_db_type(:bigserial)
        fields << "#{name} #{db_type}"
      end

      def uuid(name : Symbol)
        db_type = convert_type_to_db_type(:uuid)
        fields << "#{name} #{db_type}"
      end

      def string(name : Symbol)
        db_type = convert_type_to_db_type(:string)
        fields << "#{name} #{db_type}"
      end

      def text(name : Symbol)
        db_type = convert_type_to_db_type(:text)
        fields << "#{name} #{db_type}"
      end

      def bool(name : Symbol)
        boolean(name)
      end

      def boolean(name : Symbol)
        db_type = convert_type_to_db_type(:boolean)
        fields << "#{name} #{db_type}"
      end

      def reference(name : Symbol)
        bigint(name)
      end

      def int(name : Symbol)
        integer(name)
      end

      def integer(name : Symbol)
        db_type = convert_type_to_db_type(:integer)
        fields << "#{name} #{db_type}"
      end

      def bigint(name : Symbol)
        biginteger(name)
      end

      def biginteger(name : Symbol)
        db_type = convert_type_to_db_type(:biginteger)
        fields << "#{name} #{db_type}"
      end

      def float(name : Symbol)
        db_type = convert_type_to_db_type(:float)
        fields << "#{name} #{db_type}"
      end

      def real(name : Symbol)
        db_type = convert_type_to_db_type(:real)
        fields << "#{name} #{db_type}"
      end

      def time(name : Symbol)
        timestamp(name)
      end

      def timestamp(name : Symbol)
        db_type = convert_type_to_db_type(:timestamp)
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

      def convert_type_to_db_type(type : Symbol)
        crystal_type = CRYSTAL_TYPES[type.to_s]
        connection.class.schema_type?(crystal_type)
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

        ddl << "CREATE TABLE \"#{table.to_s}\" ("
        ddl << fields.to_sql
        ddl << ")"
      end
    end

    def rename_table(old_table : Symbol, new_table : Symbol)
      statements << "ALTER TABLE \"#{old_table.to_s}\" RENAME TO \"#{new_table.to_s}\""
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

    def add_column(table : Symbol, column : Symbol, type : Symbol)
      fields = Fields.new(@@connection.not_nil!)
      db_type = fields.convert_type_to_db_type(type)
      statements << "ALTER TABLE \"#{table.to_s}\" ADD COLUMN \"#{column.to_s}\" #{db_type}"
    end

    def rename_column(table : Symbol, old_column : Symbol, new_column : Symbol)
      statements << "ALTER TABLE \"#{table.to_s}\" RENAME COLUMN \"#{old_column.to_s}\" TO \"#{new_column.to_s}\""
    end

    def remove_column(table : Symbol, column : Symbol)
      statements << "ALTER TABLE \"#{table.to_s}\" DROP COLUMN \"#{column.to_s}\""
    end

    def drop_index(table : Symbol, field : Symbol)
      drop_index(table, [field])
    end

    def to_sql
      statements.join("; ") + ";"
    end

    def generate_sql(direction : Symbol)
      statements.clear
      direction == :up ? up : down
      to_sql
    end
  end
end
