class Granite::ORM::Base
  def self.drop_and_create
  end
end

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    adapter_const_suffix = adapter.camelcase.id
    adapter_literal = adapter.id

    parent_table = "parent_#{ adapter_literal }s".id
    student_table = "student_#{ adapter_literal }s".id
    teacher_table = "teacher_#{ adapter_literal }s".id
    klass_table = "klass_#{ adapter_literal }s".id
    enrollment_table = "enrollment_#{ adapter_literal }s".id

    parent_class = "Parent#{ adapter_const_suffix }".id
    student_class = "Student#{ adapter_const_suffix }".id
    teacher_class = "Teacher#{ adapter_const_suffix }".id

    if adapter == "pg"
      primary_key_sql = "SERIAL PRIMARY KEY".id
      foreign_key_sql = "BIGINT".id
    elsif adapter == "mysql"
      primary_key_sql = "INT NOT NULL AUTO_INCREMENT PRIMARY KEY".id
      foreign_key_sql = "BIGINT".id
    elsif adapter == "sqlite"
      primary_key_sql = "INTEGER NOT NULL PRIMARY KEY".id
      foreign_key_sql = "INTEGER".id
    end
  %}

  require "../src/adapter/{{ adapter_literal }}"

  module GraniteExample
    class Parent{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int32
      adapter {{ adapter_literal }}
      table_name "{{ parent_table }}"

      field name : String

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS {{ parent_table }};")
        exec("CREATE TABLE {{ parent_table }} (
          id {{ primary_key_sql }},
          name VARCHAR(100)
        );
        ")
      end
    end

    class Teacher{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int32
      adapter {{ adapter_literal }}
      table_name "{{ teacher_table }}"

      field name : String

      has_many :klass_{{ adapter_literal }}

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
      primary id : Int32
      adapter {{ adapter_literal }}
      table_name "{{ student_table }}"

      field name : String

      has_many :enrollment_{{ adapter_literal }}

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS {{ student_table }};")
        exec("CREATE TABLE {{ student_table }} (
          id {{ primary_key_sql }},
          name VARCHAR(100),
          parent_id {{ foreign_key_sql }}
        );
        ")
      end
    end

    class Klass{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int32
      adapter {{ adapter_literal }}
      table_name "{{ klass_table }}"
      field name : String

      belongs_to :teacher_{{ adapter_literal }}

      has_many :enrollment_{{ adapter_literal }}

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ klass_table }}"
        exec <<-SQL
          CREATE TABLE {{ klass_table }} (
            id {{ primary_key_sql }},
            name VARCHAR(255),
            teacher_id {{ foreign_key_sql }}
          )
        SQL
      end
    end

    class Enrollment{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int32
      adapter {{ adapter_literal }}
      table_name "{{ enrollment_table }}"
      field name : String

      belongs_to :student_{{ adapter_literal }}
      belongs_to :klass_{{ adapter_literal }}

      def self.drop_and_create
        exec "DROP TABLE IF EXISTS {{ enrollment_table }}"
        exec <<-SQL
          CREATE TABLE {{ enrollment_table }} (
            id {{ primary_key_sql }},
            student_id {{ foreign_key_sql }},
            klass_id {{ foreign_key_sql }}
          )
        SQL
      end
    end

    @@model_classes << Parent{{ adapter_const_suffix }}
    @@model_classes << Teacher{{ adapter_const_suffix }}
    @@model_classes << Student{{ adapter_const_suffix }}
    @@model_classes << Klass{{ adapter_const_suffix }}
    @@model_classes << Enrollment{{ adapter_const_suffix }}

    Spec.before_each do
      Parent{{ adapter_const_suffix }}.clear
      Teacher{{ adapter_const_suffix }}.clear
      Student{{ adapter_const_suffix }}.clear
      Klass{{ adapter_const_suffix }}.clear
      Enrollment{{ adapter_const_suffix }}.clear
    end
  end

{% end %}
