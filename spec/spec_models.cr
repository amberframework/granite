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

    parent_class = "Parent#{ adapter_const_suffix }".id
    student_class = "Student#{ adapter_const_suffix }".id
    teacher_class = "Teacher#{ adapter_const_suffix }".id

    if adapter == "pg"
      primary_key_sql = "id SERIAL PRIMARY KEY".id
    elsif adapter == "mysql"
      primary_key_sql = "id INT NOT NULL AUTO_INCREMENT PRIMARY KEY".id
    elsif adapter == "sqlite"
      primary_key_sql = "id INTEGER NOT NULL PRIMARY KEY".id
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
          {{ primary_key_sql }},
          name VARCHAR(10)
        );
        ")
      end
    end

    class Teacher{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int32
      adapter {{ adapter_literal }}
      table_name "{{ teacher_table }}"

      field name : String

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS {{ teacher_table }};")
        exec("CREATE TABLE {{ teacher_table }} (
          {{ primary_key_sql }},
          name VARCHAR(10)
        );
        ")
      end
    end

    class Student{{ adapter_const_suffix }} < Granite::ORM::Base
      primary id : Int32
      adapter {{ adapter_literal }}
      table_name "{{ student_table }}"

      field name : String

      def self.drop_and_create
        exec("DROP TABLE IF EXISTS {{ student_table }};")
        exec("CREATE TABLE {{ student_table }} (
          {{ primary_key_sql }},
          name VARCHAR(10)
        );
        ")
      end
    end

    @@model_classes << Parent{{ adapter_const_suffix }}
    @@model_classes << Teacher{{ adapter_const_suffix }}
    @@model_classes << Student{{ adapter_const_suffix }}

    Spec.before_each do
      Parent{{ adapter_const_suffix }}.clear
      Teacher{{ adapter_const_suffix }}.clear
      Student{{ adapter_const_suffix }}.clear
    end
  end

{% end %}
