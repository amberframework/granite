class Granite::ORM::Base
  def self.drop_and_create
  end
end

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    adapter_literal = adapter.id

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

  module {{adapter.capitalize.id}}
    class Parent < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name parents

      field name : String
      {{ timestamp_fields }}

      has_many :students

      validate :name, "Name cannot be blank" do |parent| 
        !parent.name.to_s.blank?
      end

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS #{ quoted_table_name };")
        exec("CREATE TABLE #{ quoted_table_name } (
          id {{ primary_key_sql }},
          {{ created_at_sql }}
          {{ updated_at_sql }}
          name VARCHAR(100)
        );
        ")
      end
    end

    class Teacher < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name teachers

      field name : String

      has_many :klasss

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS #{ quoted_table_name };")
        exec("CREATE TABLE #{ quoted_table_name } (
          id {{ primary_key_sql }},
          name VARCHAR(100)
        );
        ")
      end
    end

    class Student < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name students

      field name : String

      has_many :enrollments
      has_many :klasss, through: :enrollments

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS #{ quoted_table_name };")
        exec("CREATE TABLE #{ quoted_table_name } (
          id {{ primary_key_sql }},
          name VARCHAR(100),
          parent_id {{ foreign_key_sql }}
        );
        ")
      end
    end

    class Klass < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name klasss
      field name : String

      belongs_to :teacher

      has_many :enrollments
      has_many :students, through: :enrollments

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS #{ quoted_table_name }"
        exec <<-SQL
          CREATE TABLE #{ quoted_table_name } (
            id {{ primary_key_sql }},
            name VARCHAR(255),
            teacher_id {{ foreign_key_sql }}
          )
        SQL
      end
    end

    class Enrollment < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name enrollments

      belongs_to :student
      belongs_to :klass

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS #{ quoted_table_name }"
        exec <<-SQL
          CREATE TABLE #{ quoted_table_name } (
            id {{ primary_key_sql }},
            student_id {{ foreign_key_sql }},
            klass_id {{ foreign_key_sql }}
          )
        SQL
      end
    end

    class School < Granite::ORM::Base
      adapter {{ adapter_literal }}
      primary custom_id : Int64
      field name : String

      table_name schools

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS #{ quoted_table_name }"
        exec <<-SQL
          CREATE TABLE #{ quoted_table_name } (
            custom_id {{ primary_key_sql }},
            name VARCHAR(255)
          )
        SQL
      end
    end

    class Nation::County < Granite::ORM::Base
      adapter {{ adapter_literal }}
      primary id : Int64
      table_name nation_countys

      field name : String

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS #{ quoted_table_name }"
        exec <<-SQL
          CREATE TABLE #{ quoted_table_name } (
            id {{ primary_key_sql }},
            name VARCHAR(255)
          )
        SQL
      end
    end

    class Review < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name reviews
      field name : String
      field downvotes : Int32
      field upvotes : Int64
      field sentiment : Float32
      field interest : Float64
      field published : Bool
      field created_at : Time

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS #{ quoted_table_name }"
        exec <<-SQL
          CREATE TABLE #{ quoted_table_name } (
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

    class Empty < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name emptys
      primary id : Int64

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS #{ quoted_table_name }"
        exec <<-SQL
          CREATE TABLE #{ quoted_table_name } (
            id {{ primary_key_sql }}
          )
        SQL
      end
    end

    class ReservedWord < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name "select"
      field all : String

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS #{ quoted_table_name }"
        exec <<-SQL
          CREATE TABLE #{ quoted_table_name } (
            id {{ primary_key_sql }},
            #{quote("all")} VARCHAR(255)
          )
        SQL
      end
    end

    Parent.drop_and_create
    Teacher.drop_and_create
    Student.drop_and_create
    Klass.drop_and_create
    Enrollment.drop_and_create
    School.drop_and_create
    Nation::County.drop_and_create
    Review.drop_and_create
    Empty.drop_and_create
    ReservedWord.drop_and_create

    Spec.before_each do
      Parent.clear
      Teacher.clear
      Student.clear
      Klass.clear
      Enrollment.clear
      School.clear
      Nation::County.clear
      Review.clear
      Empty.clear
      ReservedWord.clear
    end
  end
{% end %}
