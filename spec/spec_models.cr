{% for adapter in GraniteExample::ADAPTERS %}
  {% adapter_literal = adapter.id %}
  require "../src/adapter/{{ adapter_literal }}"

  module {{adapter.capitalize.id}}
    class Parent < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name parents

      field name : String
      timestamps

      has_many :students

      validate :name, "Name cannot be blank" do |parent|
        !parent.name.to_s.blank?
      end
    end

    class Teacher < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name teachers

      field name : String

      has_many :klasss
    end

    class Student < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name students

      field name : String

      has_many :enrollments
      has_many :klasss, through: :enrollments
    end

    class Klass < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name klasss
      field name : String

      belongs_to :teacher

      has_many :enrollments
      has_many :students, through: :enrollments
    end

    class Enrollment < Granite::ORM::Base
      primary id : Int64
      adapter {{ adapter_literal }}
      table_name enrollments

      belongs_to :student
      belongs_to :klass
    end

    class School < Granite::ORM::Base
      adapter {{ adapter_literal }}
      primary custom_id : Int64
      field name : String

      table_name schools
    end

    class Nation::County < Granite::ORM::Base
      adapter {{ adapter_literal }}
      primary id : Int64
      table_name nation_countys

      field name : String
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
    end

    class Empty < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name emptys
      primary id : Int64
    end

    class ReservedWord < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name "select"
      field all : String
    end

    class Callback < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name callbacks
      primary id : Int64
      field name : String

      property history : IO::Memory = IO::Memory.new

      {% for name in Granite::ORM::Callbacks::CALLBACK_NAMES %}
        {{name.id}} _{{name.id}}
        private def _{{name.id}}
          history << "{{name.id}}\n"
        end
      {% end %}
    end

    class Kvs < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name kvss
      primary k : String, auto: false
      field v : String
    end

    class Book < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name books
      has_many :book_reviews

      primary id : Int32
      field name : String
    end

    class BookReview < Granite::ORM::Base
      adapter {{ adapter_literal }}
      table_name book_reviews
      belongs_to :book, book_id : Int32

      primary id : Int32
      field body : String
    end

    Parent.migrator.drop_and_create
    Teacher.migrator.drop_and_create
    Student.migrator.drop_and_create
    Klass.migrator.drop_and_create
    Enrollment.migrator.drop_and_create
    School.migrator.drop_and_create
    Nation::County.migrator.drop_and_create
    Review.migrator.drop_and_create
    Empty.migrator.drop_and_create
    ReservedWord.migrator.drop_and_create
    Callback.migrator.drop_and_create
    Kvs.migrator.drop_and_create
    Book.migrator.drop_and_create
    BookReview.migrator.drop_and_create
  end
{% end %}
