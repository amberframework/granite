class Granite::ORM::Base
  def self.drop_and_create
  end
end

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    adapter_const_suffix = adapter.camelcase.id
    adapter_suffix = "_#{adapter.id}".id
    adapter_literal = adapter.id

    parent_table = "parent_#{adapter_literal}s".id
    student_table = "student_#{adapter_literal}s".id
    teacher_table = "teacher_#{adapter_literal}s".id
    klass_table = "klass_#{adapter_literal}s".id
    enrollment_table = "enrollment_#{adapter_literal}s".id
    school_table = "school_#{adapter_literal}s".id
    nation_county_table = "nation_county_#{adapter_literal}s".id
    review_table = "review_#{adapter_literal}s".id
    empty_table = "empty_#{adapter_literal}s".id

    if adapter == "pg"
      primary_key_sql = "BIGSERIAL PRIMARY KEY".id
      foreign_key_sql = "BIGINT".id
      created_at_sql = "created_at TIMESTAMP,".id
      updated_at_sql = "updated_at TIMESTAMP,".id
      timestamp_fields = "timestamps".id
    elsif adapter == "mysql"
      primary_key_sql = "BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY".id
      foreign_key_sql = "BIGINT".id
      created_at_sql = "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,".id
      updated_at_sql = "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,".id
      timestamp_fields = "timestamps".id
    elsif adapter == "sqlite"
      primary_key_sql = "INTEGER NOT NULL PRIMARY KEY".id
      foreign_key_sql = "INTEGER".id
      created_at_sql = "".id
      updated_at_sql = "".id
      timestamp_fields = "".id
    end
  %}

  require "../src/adapter/{{ adapter_literal }}"

    class Parent{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name "{{ parent_table }}"

      field name : String
      {{ timestamp_fields }}

      has_many :student_{{ adapter_literal }}s

      validate :name, "Name cannot be blank" do
        !(name.not_nil!.blank?)
      end

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS {{ parent_table }};")
        exec("CREATE TABLE {{ parent_table }} (
          id {{ primary_key_sql }},
          {{ created_at_sql }}
          {{ updated_at_sql }}
          name VARCHAR(100)
        );
        ")
      end
    end

    class Teacher{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name "{{ teacher_table }}"

      field name : String

      has_many :klass_{{ adapter_literal }}s

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS {{ teacher_table }};")
        exec("CREATE TABLE {{ teacher_table }} (
          id {{ primary_key_sql }},
          name VARCHAR(100)
        );
        ")
      end
    end

    class Student{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name "{{ student_table }}"

      field name : String

      has_many :enrollment_{{ adapter_literal }}s
      has_many :klass_{{ adapter_literal }}s, through: :enrollment_{{ adapter_literal }}s

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS {{ student_table }};")
        exec("CREATE TABLE {{ student_table }} (
          id {{ primary_key_sql }},
          name VARCHAR(100),
          parent{{ adapter_suffix }}_id {{ foreign_key_sql }}
        );
        ")
      end
    end

    class Klass{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name "{{ klass_table }}"
      field name : String

      belongs_to :teacher_{{ adapter_literal }}

      has_many :enrollment_{{ adapter_literal }}s
      has_many :student_{{ adapter_literal }}s, through: :enrollment_{{ adapter_literal }}s

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ klass_table }}"
        exec <<-SQL
          CREATE TABLE {{ klass_table }} (
            id {{ primary_key_sql }},
            name VARCHAR(255),
            teacher{{ adapter_suffix }}_id {{ foreign_key_sql }}
          )
        SQL
      end
    end

    class Enrollment{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name "{{ enrollment_table }}"

      belongs_to :student_{{ adapter_literal }}
      belongs_to :klass_{{ adapter_literal }}

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ enrollment_table }}"
        exec <<-SQL
          CREATE TABLE {{ enrollment_table }} (
            id {{ primary_key_sql }},
            student{{ adapter_suffix }}_id {{ foreign_key_sql }},
            klass{{ adapter_suffix }}_id {{ foreign_key_sql }}
          )
        SQL
      end
    end

    class School{{ adapter_const_suffix }} < Granite::ORM::Base
      adapter {{ adapter_literal }}
      primary custom_id : Int64
      field name : String

      table_name "{{ school_table }}"

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ school_table }}"
        exec <<-SQL
          CREATE TABLE {{ school_table }} (
            custom_id {{ primary_key_sql }},
            name VARCHAR(255)
          )
        SQL
      end
    end

    class Nation::County{{ adapter_const_suffix }} < Granite::ORM::Base
      adapter {{ adapter_literal }}
      primary id : Int64
      table_name "{{ nation_county_table }}"

      field name : String

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ nation_county_table }}"
        exec <<-SQL
          CREATE TABLE {{ nation_county_table }} (
            id {{ primary_key_sql }},
            name VARCHAR(255)
          )
        SQL
      end
    end

    class Review{{ adapter_const_suffix }} < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name "{{ review_table }}"
      field name : String
      field downvotes : Int32
      field upvotes : Int64
      field sentiment : Float32
      field interest : Float64
      field published : Bool
      field created_at : Time

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ review_table }}"
        exec <<-SQL
          CREATE TABLE {{ review_table }} (
            id {{ primary_key_sql }},
            name VARCHAR(255),
            downvotes INT,
            upvotes BIGINT,
            sentiment FLOAT,
            interest REAL,
            published BOOL,
            created_at TIMESTAMP
          )
        SQL
      end
    end

    class Empty{{ adapter_const_suffix }} < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name "{{ empty_table }}"
      primary id : Int64

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ empty_table }}"
        exec <<-SQL
          CREATE TABLE {{ empty_table }} (
            id {{ primary_key_sql }}
          )
        SQL
      end
    end

    module GraniteExample
      @@model_classes << Parent{{ adapter_const_suffix }}
      @@model_classes << Teacher{{ adapter_const_suffix }}
      @@model_classes << Student{{ adapter_const_suffix }}
      @@model_classes << Klass{{ adapter_const_suffix }}
      @@model_classes << Enrollment{{ adapter_const_suffix }}
      @@model_classes << School{{ adapter_const_suffix }}
      @@model_classes << Nation::County{{ adapter_const_suffix }}
      @@model_classes << Review{{ adapter_const_suffix }}
      @@model_classes << Empty{{ adapter_const_suffix }}
    end

    Spec.before_each do
      Parent{{ adapter_const_suffix }}.clear
      Teacher{{ adapter_const_suffix }}.clear
      Student{{ adapter_const_suffix }}.clear
      Klass{{ adapter_const_suffix }}.clear
      Enrollment{{ adapter_const_suffix }}.clear
      School{{ adapter_const_suffix }}.clear
      Nation::County{{ adapter_const_suffix }}.clear
      Review{{ adapter_const_suffix }}.clear
      Empty{{ adapter_const_suffix }}.clear
    end

{% end %}
