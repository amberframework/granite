require "uuid"

class Granite::Base
  def self.drop_and_create
  end
end

{% begin %}
  {% adapter_literal = env("CURRENT_ADAPTER").id %}

  class Chat < Granite::Base
    connection {{ adapter_literal }}
    table chats

    column id : Int64, primary: true

    column name : String

    has_one settings : ChatSettings, foreign_key: :chat_id
  end

  class ChatSettings < Granite::Base
    connection {{ adapter_literal }}
    table chat_settings

    belongs_to chat : Chat, primary: true

    column flood_limit : Int32
  end

  class Parent < Granite::Base
    connection {{ adapter_literal }}
    table parents

    column id : Int64, primary: true
    column name : String?
    timestamps

    has_many :students, class_name: Student

    validate :name, "Name cannot be blank" do |parent|
      !parent.name.to_s.blank?
    end
  end

  class Teacher < Granite::Base
    connection {{ adapter_literal }}
    table teachers

    column id : Int64, primary: true
    column name : String?

    has_many :klasses, class_name: Klass
  end

  class Student < Granite::Base
    connection {{ adapter_literal }}
    table students

    column id : Int64, primary: true
    column name : String?

    has_many :enrollments, class_name: Enrollment
    has_many :klasses, class_name: Klass, through: :enrollments
  end

  class Klass < Granite::Base
    connection {{ adapter_literal }}
    table klasses

    column id : Int64, primary: true
    column name : String?

    belongs_to teacher : Teacher

    has_many :enrollments, class_name: Enrollment
    has_many :students, class_name: Student, through: :enrollments
  end

  class Enrollment < Granite::Base
    connection {{ adapter_literal }}
    table enrollments

    column id : Int64, primary: true

    belongs_to :student
    belongs_to :klass
  end

  class School < Granite::Base
    connection {{ adapter_literal }}
    table schools

    column custom_id : Int64, primary: true
    column name : String?
  end

  class User < Granite::Base
    connection {{ adapter_literal }}
    table users

    column id : Int64, primary: true
    column email : String?

    has_one :profile
  end

  class Character < Granite::Base
    connection {{ adapter_literal }}
    table characters

    column character_id : Int32, primary: true
    column name : String
  end

  class Courier < Granite::Base
    connection {{ adapter_literal }}
    table couriers

    column courier_id : Int32, primary: true, auto: false
    column issuer_id : Int32

    belongs_to service : CourierService, primary_key: "owner_id"
    has_one issuer : Character, primary_key: "issuer_id", foreign_key: "character_id"
  end

  class CourierService < Granite::Base
    connection {{ adapter_literal }}
    table services

    column owner_id : Int64, primary: true, auto: false
    column name : String

    has_many :couriers, class_name: Courier, foreign_key: "service_id"
  end

  class Profile < Granite::Base
    connection {{ adapter_literal }}
    table profiles

    column id : Int64, primary: true
    column name : String?

    belongs_to :user
  end

  class Nation::County < Granite::Base
    connection {{ adapter_literal }}
    table nation_counties

    column id : Int64, primary: true
    column name : String?
  end

  class Review < Granite::Base
    connection {{ adapter_literal }}
    table reviews

    column id : Int64, primary: true
    column name : String?
    column downvotes : Int32?
    column upvotes : Int64?
    column sentiment : Float32?
    column interest : Float64?
    column published : Bool?
    column created_at : Time?
  end

  class Empty < Granite::Base
    connection {{ adapter_literal }}
    table empties

    column id : Int64, primary: true
  end

  class ReservedWord < Granite::Base
    connection {{ adapter_literal }}
    table "select"

    column id : Int64, primary: true
    column all : String?
  end

  class Callback < Granite::Base
    connection {{ adapter_literal }}
    table callbacks

    column id : Int64, primary: true
    column name : String?

    property history : IO::Memory = IO::Memory.new

    {% for name in Granite::Callbacks::CALLBACK_NAMES %}
      {{name.id}} _{{name.id}}
      private def _{{name.id}}
        history << "{{name.id}}\n"
      end
    {% end %}
  end

  class CallbackWithAbort < Granite::Base
    connection {{ adapter_literal }}
    table callbacks_with_abort

    column abort_at : String, primary: true, auto: false
    column do_abort : Bool?
    column name : String?

    property history : IO::Memory = IO::Memory.new

    {% for name in Granite::Callbacks::CALLBACK_NAMES %}
      {{name.id}} do
        abort! if do_abort && abort_at == "{{name.id}}"
        history << "{{name.id}}\n"
      end
    {% end %}
  end

  class Kvs < Granite::Base
    connection {{ adapter_literal }}
    table kvs

    column k : String, primary: true, auto: false
    column v : String?
  end

  class Person < Granite::Base
    connection {{ adapter_literal }}
    table people

    column id : Int64, primary: true
    column name : String?
  end

  class Company < Granite::Base
    connection {{ adapter_literal }}
    table companies

    column id : Int32, primary: true
    column name : String?
  end

  class Book < Granite::Base
    connection {{ adapter_literal }}
    table books

    column id : Int32, primary: true
    column name : String?

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    belongs_to publisher : Company, foreign_key: publisher_id : Int32?
    has_many :book_reviews, class_name: BookReview
    belongs_to author : Person
  end

  class BookReview < Granite::Base
    connection {{ adapter_literal }}
    table book_reviews

    column id : Int32, primary: true
    column body : String?

    belongs_to book : Book, foreign_key: book_id : Int32?
  end

  class Item < Granite::Base
    connection {{ adapter_literal }}
    table items

    column item_id : String, primary: true, auto: false
    column item_name : String?

    before_create :generate_uuid

    def generate_uuid
      @item_id = UUID.random.to_s
    end
  end

  class NonAutoDefaultPK < Granite::Base
    connection {{ adapter_literal }}
    table non_auto_default_pk

    column id : Int64, primary: true, auto: false
    column name : String?
  end

  class NonAutoCustomPK < Granite::Base
    connection {{ adapter_literal }}
    table non_auto_custom_pk

    column custom_id : Int64, primary: true, auto: false
    column name : String?
  end

  class Article < Granite::Base
    connection {{ adapter_literal }}
    table articles

    column id : Int64, primary: true
    column articlebody : String?
  end

  class Comment < Granite::Base
    connection {{ adapter_literal }}
    table comments

    column id : Int64, primary: true
    column commentbody : String?
    column articleid : Int64?
  end

  class SongThread < Granite::Base
    connection {{ env("CURRENT_ADAPTER").id }}

    column id : Int64, primary: true
    column name : String?
  end

  class CustomSongThread < Granite::Base
    connection {{ env("CURRENT_ADAPTER").id }}
    table custom_table_name

    column custom_primary_key : Int64, primary: true
    column name : String?
  end

  @[JSON::Serializable::Options(emit_nulls: true)]
  @[YAML::Serializable::Options(emit_nulls: true)]
  class TodoEmitNull < Granite::Base
    connection {{ adapter_literal }}
    table todos

    column id : Int64, primary: true
    column name : String?
    column priority : Int32?
    timestamps
  end

  class Todo < Granite::Base
    connection {{ adapter_literal }}
    table todos

    column id : Int64, primary: true
    column name : String?
    column priority : Int32?
    timestamps
  end

  class AfterInit < Granite::Base
    connection {{ adapter_literal }}
    table after_json_init

    column id : Int64, primary: true
    column name : String?
    column priority : Int32?

    def after_initialize
      @priority = 1000
    end
  end

  class ArticleViewModel < Granite::Base
    connection {{ adapter_literal }}

    column id : Int64, primary: true
    column articlebody : String?
    column commentbody : String?

    select_statement <<-SQL
      SELECT articles.id, articles.articlebody, comments.commentbody FROM articles JOIN comments ON comments.articleid = articles.id
    SQL
  end

  # Only PG supports array types
  {% if env("CURRENT_ADAPTER") == "pg" %}
    class ArrayModel < Granite::Base
      connection {{ adapter_literal }}

      column id : Int32, primary: true
      column str_array : Array(String)?
      column i16_array : Array(Int16)?
      column i32_array : Array(Int32)?
      column i64_array : Array(Int64)?
      column f32_array : Array(Float32)?
      column f64_array : Array(Float64)? = [] of Float64
      column bool_array : Array(Bool)?
    end
    ArrayModel.migrator.drop_and_create
  {% end %}

  class UUIDModel < Granite::Base
    connection {{ adapter_literal }}
    table uuids

    column uuid : UUID?, primary: true, converter: Granite::Converters::Uuid(String)
  end

  class UUIDNaturalModel < Granite::Base
    connection {{ adapter_literal }}
    table uuids

    column uuid : UUID, primary: true, converter: Granite::Converters::Uuid(String), auto: false
    column field_uuid : UUID?, converter: Granite::Converters::Uuid(String)
  end

  class TodoJsonOptions < Granite::Base
    connection {{ adapter_literal }}
    table todos_json

    column id : Int64, primary: true

    @[JSON::Field(key: "task_name")]
    column name : String?

    @[JSON::Field(ignore: true)]
    column priority : Int32?

    @[JSON::Field(ignore: true)]
    column updated_at : Time?

    @[JSON::Field(key: "posted")]
    column created_at : Time?
  end

  class TodoYamlOptions < Granite::Base
    connection {{ adapter_literal }}
    table todos_yaml

    column id : Int64, primary: true

    @[YAML::Field(key: "task_name")]
    column name : String?

    @[YAML::Field(ignore: true)]
    column priority : Int32?

    @[YAML::Field(ignore: true)]
    column updated_at : Time?

    @[YAML::Field(key: "posted")]
    column created_at : Time?
  end

  class DefaultValues < Granite::Base
    connection {{ adapter_literal }}
    table defaults

    column id : Int64, primary: true
    column name : String = "Jim"
    column is_alive : Bool = true
    column age : Float64 = 0.0
  end

  class TimeTest < Granite::Base
    connection {{ adapter_literal }}
    table times

    column id : Int64, primary: true
    column test : Time?
    column name : String?
    timestamps
  end

  class ManualColumnType < Granite::Base
    connection {{ adapter_literal }}
    table manual_column_types

    column id : Int64, primary: true
    column foo : UUID?, column_type: "DECIMAL(12, 10)"
  end

  class EventCon < Granite::Base
    connection {{ adapter_literal }}
    table "event_cons"

    column id : Int64, primary: true
    column con_name : String
    column event_name : String?

    select_statement <<-SQL
    select con_name FROM event_cons
    SQL
  end

  class StringConversion < Granite::Base
    connection {{ adapter_literal }}
    table "string_conversions"

    belongs_to :user

    column id : Int64, primary: true
    column int32 : Int32
    column float32 : Float32
    column float : Float64
  end

  class BoolModel < Granite::Base
    connection {{ adapter_literal }}
    table "bool_model"

    column id : Int64, primary: true
    column active : Bool = true
  end

  struct MyType
    include JSON::Serializable

    def initialize; end

    property name : String = "Jim"
    property age : Int32 = 12
  end

  enum MyEnum
    Zero
    One
    Two
    Three
    Four
  end

  class EnumModel < Granite::Base
    connection {{ adapter_literal }}
    table enum_model

    column id : Int64, primary: true
    column my_enum : MyEnum?, column_type: "TEXT", converter: Granite::Converters::Enum(MyEnum, String)
  end

  class MyApp::Namespace::Model < Granite::Base
    connection {{ adapter_literal }}

    column id : Int64, primary: true
  end

  {% if env("CURRENT_ADAPTER") == "pg" %}
    class ConverterModel < Granite::Base
      connection {{ adapter_literal }}
      table converters

      column id : Int64, primary: true

      column binary_json : MyType?, column_type: "BYTEA", converter: Granite::Converters::Json(MyType, Bytes)
      column string_json : MyType?, column_type: "JSON", converter: Granite::Converters::Json(MyType, JSON::Any)
      column string_jsonb : MyType?, column_type: "JSONB", converter: Granite::Converters::Json(MyType, JSON::Any)

      column smallint_enum : MyEnum?, column_type: "SMALLINT", converter: Granite::Converters::Enum(MyEnum, Int16)
      column bigint_enum : MyEnum?, column_type: "BIGINT", converter: Granite::Converters::Enum(MyEnum, Int64)
      column string_enum : MyEnum?, column_type: "TEXT", converter: Granite::Converters::Enum(MyEnum, String)
      column enum_enum : MyEnum?, column_type: "my_enum_type", converter: Granite::Converters::Enum(MyEnum, Bytes)
      column binary_enum : MyEnum?, column_type: "BYTEA", converter: Granite::Converters::Enum(MyEnum, Bytes)

      column string_uuid : UUID?, converter: Granite::Converters::Uuid(String) # Test PG native UUID type
      column binary_uuid : UUID?, column_type: "BYTEA", converter: Granite::Converters::Uuid(Bytes)

      column numeric : Float64?, column_type: "DECIMAL(21, 20)", converter: Granite::Converters::PgNumeric
    end
    ConverterModel.exec(<<-TYPE
      DO $$
      BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'my_enum_type') THEN
            CREATE TYPE my_enum_type AS ENUM ('Zero', 'One', 'Two', 'Three', 'Four');
          END IF;
      END$$;
      TYPE
    )
  {% elsif env("CURRENT_ADAPTER") == "sqlite" %}
    class ConverterModel < Granite::Base
      connection {{ adapter_literal }}
      table converters

      column id : Int64, primary: true

      column binary_json : MyType?, column_type: "BLOB", converter: Granite::Converters::Json(MyType, Bytes)
      column string_json : MyType?, column_type: "TEXT", converter: Granite::Converters::Json(MyType, String)

      column int_enum : MyEnum?, column_type: "INTEGER", converter: Granite::Converters::Enum(MyEnum, Int64)
      column string_enum : MyEnum?, column_type: "TEXT", converter: Granite::Converters::Enum(MyEnum, String)
      column binary_enum : MyEnum?, column_type: "BLOB", converter: Granite::Converters::Enum(MyEnum, String)

      column string_uuid : UUID?, column_type: "TEXT", converter: Granite::Converters::Uuid(String)
      column binary_uuid : UUID?, column_type: "BLOB", converter: Granite::Converters::Uuid(Bytes)
    end
  {% elsif env("CURRENT_ADAPTER") == "mysql" %}
    class ConverterModel < Granite::Base
      connection {{ adapter_literal }}
      table converters

      column id : Int64, primary: true

      column binary_json : MyType?, column_type: "BLOB", converter: Granite::Converters::Json(MyType, Bytes)
      column string_json : MyType?, column_type: "TEXT", converter: Granite::Converters::Json(MyType, String)

      column int_enum : MyEnum?, column_type: "INTEGER", converter: Granite::Converters::Enum(MyEnum, Int32)
      column string_enum : MyEnum?, column_type: "VARCHAR(5)", converter: Granite::Converters::Enum(MyEnum, String)
      column enum_enum : MyEnum?, column_type: "ENUM('Zero', 'One', 'Two', 'Three', 'Four')", converter: Granite::Converters::Enum(MyEnum, String)
      column binary_enum : MyEnum?, column_type: "BLOB", converter: Granite::Converters::Enum(MyEnum, Bytes)

      column string_uuid : UUID?, column_type: "TEXT", converter: Granite::Converters::Uuid(String)
      column binary_uuid : UUID?, column_type: "BLOB", converter: Granite::Converters::Uuid(Bytes)
    end
  {% end %}

  module Validators
    class NilTest < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true

      column first_name_not_nil : String?
      column last_name_not_nil : String?
      column age_not_nil : Int32?
      column born_not_nil : Bool?
      column value_not_nil : Float32?

      column first_name : String?
      column last_name : String?
      column age : Int32?
      column born : Bool?
      column value : Float32?

      validate_not_nil "first_name_not_nil"
      validate_not_nil :last_name_not_nil
      validate_not_nil :age_not_nil
      validate_not_nil "born_not_nil"
      validate_not_nil :value_not_nil

      validate_is_nil "first_name"
      validate_is_nil :last_name
      validate_is_nil :age
      validate_is_nil "born"
      validate_is_nil :value
    end

    class BlankTest < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true

      column first_name_not_blank : String?
      column last_name_not_blank : String?

      column first_name_is_blank : String?
      column last_name_is_blank : String?

      validate_not_blank "first_name_not_blank"
      validate_not_blank "last_name_not_blank"

      validate_is_blank "first_name_is_blank"
      validate_is_blank "last_name_is_blank"
    end

    class ChoiceTest < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true

      column number_symbol : Int32?
      column type_array_symbol : String?

      column number_string : Int32?
      column type_array_string : String?

      validate_is_valid_choice :number_symbol, [1, 2, 3]
      validate_is_valid_choice :type_array_symbol, [:internal, :external, :third_party]
      validate_is_valid_choice "number_string", [4, 5, 6]
      validate_is_valid_choice "type_array_string", ["internal", "external", "third_party"]
    end

    class LessThanTest < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true

      column int_32_lt : Int32?
      column float_32_lt : Float32?

      column int_32_lte : Int32?
      column float_32_lte : Float32?

      validate_less_than "int_32_lt", 10
      validate_less_than :float_32_lt, 20.5

      validate_less_than :int_32_lte, 50, true
      validate_less_than "float_32_lte", 100.25, true
    end

    class GreaterThanTest < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true

      column int_32_lt : Int32?
      column float_32_lt : Float32?

      column int_32_lte : Int32?
      column float_32_lte : Float32?

      validate_greater_than "int_32_lt", 10
      validate_greater_than :float_32_lt, 20.5

      validate_greater_than :int_32_lte, 50, true
      validate_greater_than "float_32_lte", 100.25, true
    end

    class LengthTest < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true
      column title : String?
      column description : String?

      validate_min_length :title, 5
      validate_max_length :description, 25
    end

    class PersonUniqueness < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true
      column name : String?

      validate_uniqueness :name
    end

    class ExclusionTest < Granite::Base
      connection {{ adapter_literal }}

      column id : Int64, primary: true
      column name : String?

      validate_exclusion :name, ["test_name"]
    end
  end
{% end %}

{% for model in Granite::Base.all_subclasses %}
  {{model.id}}.migrator.drop_and_create
{% end %}
