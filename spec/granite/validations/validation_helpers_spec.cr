require "../../spec_helper"

{% begin %}
  {% adapter_literal = env("CURRENT_ADAPTER").id %}
  class NilTest < Granite::Base
    adapter {{ adapter_literal }}

    field first_name_not_nil : String
    field last_name_not_nil : String
    field age_not_nil : Int32
    field born_not_nil : Bool
    field value_not_nil : Float32

    field first_name : String
    field last_name : String
    field age : Int32
    field born : Bool
    field value : Float32

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
    adapter {{ adapter_literal }}

    field first_name_not_blank : String
    field last_name_not_blank : String

    field first_name_is_blank : String
    field last_name_is_blank : String

    validate_not_blank "first_name_not_blank"
    validate_not_blank "last_name_not_blank"

    validate_is_blank "first_name_is_blank"
    validate_is_blank "last_name_is_blank"
  end

  class ChoiceTest < Granite::Base
    adapter {{ adapter_literal }}

    field number_symbol : Int32
    field type_array_symbol : String

    field number_string : Int32
    field type_array_string : String

    validate_is_valid_choice :number_symbol, [1, 2, 3]
    validate_is_valid_choice :type_array_symbol, [:internal, :external, :third_party]
    validate_is_valid_choice "number_string", [4, 5, 6]
    validate_is_valid_choice "type_array_string", ["internal", "external", "third_party"]
  end

  class LessThanTest < Granite::Base
    adapter {{ adapter_literal }}

    field int_32_lt : Int32
    field float_32_lt : Float32

    field int_32_lte : Int32
    field float_32_lte : Float32

    validate_less_than "int_32_lt", 10
    validate_less_than :float_32_lt, 20.5

    validate_less_than :int_32_lte, 50, true
    validate_less_than "float_32_lte", 100.25, true
  end

  class GreaterThanTest < Granite::Base
    adapter {{ adapter_literal }}

    field int_32_lt : Int32
    field float_32_lt : Float32

    field int_32_lte : Int32
    field float_32_lte : Float32

    validate_greater_than "int_32_lt", 10
    validate_greater_than :float_32_lt, 20.5

    validate_greater_than :int_32_lte, 50, true
    validate_greater_than "float_32_lte", 100.25, true
  end

  class LengthTest < Granite::Base
    adapter {{ adapter_literal }}

    field title : String
    field description : String

    validate_min_length :title, 5
    validate_max_length :description, 25
  end

  class PersonUniqueness < Granite::Base
    adapter {{ adapter_literal }}

    field name : String

    validate_uniqueness :name
  end

  describe Granite::ValidationHelpers do
    context "Nil" do
      it "should work for is_nil and not_nil for all data types" do
        nil_test = NilTest.new

        nil_test.first_name = "John"
        nil_test.last_name = "Smith"
        nil_test.age = 32
        nil_test.born = true
        nil_test.value = 123.56.to_f32

        nil_test.save

        nil_test.errors.size.should eq 10
        nil_test.errors[0].message.should eq "first_name_not_nil must not be nil"
        nil_test.errors[1].message.should eq "last_name_not_nil must not be nil"
        nil_test.errors[2].message.should eq "age_not_nil must not be nil"
        nil_test.errors[3].message.should eq "born_not_nil must not be nil"
        nil_test.errors[4].message.should eq "value_not_nil must not be nil"
        nil_test.errors[5].message.should eq "first_name must be nil"
        nil_test.errors[6].message.should eq "last_name must be nil"
        nil_test.errors[7].message.should eq "age must be nil"
        nil_test.errors[8].message.should eq "born must be nil"
        nil_test.errors[9].message.should eq "value must be nil"
      end
    end

    context "Blank" do
      it "should work for is_blank and not_blank" do
        blank_test = BlankTest.new

        blank_test.first_name_not_blank = ""
        blank_test.last_name_not_blank = "      "

        blank_test.first_name_is_blank = "foo"
        blank_test.last_name_is_blank = "  bar  "

        blank_test.save

        blank_test.errors.size.should eq 4
        blank_test.errors[0].message.should eq "first_name_not_blank must not be blank"
        blank_test.errors[1].message.should eq "last_name_not_blank must not be blank"
        blank_test.errors[2].message.should eq "first_name_is_blank must be blank"
        blank_test.errors[3].message.should eq "last_name_is_blank must be blank"
      end
    end

    context "Choice" do
      it "should work for is_valid_choice" do
        choice_test = ChoiceTest.new

        choice_test.number_symbol = 4
        choice_test.type_array_symbol = "foo"

        choice_test.number_string = 2
        choice_test.type_array_string = "bar"

        choice_test.save

        choice_test.errors.size.should eq 4
        choice_test.errors[0].message.should eq "number_symbol has an invalid choice. Valid choices are: 1,2,3"
        choice_test.errors[1].message.should eq "type_array_symbol has an invalid choice. Valid choices are: internal,external,third_party"
        choice_test.errors[2].message.should eq "number_string has an invalid choice. Valid choices are: 4,5,6"
        choice_test.errors[3].message.should eq "type_array_string has an invalid choice. Valid choices are: internal,external,third_party"
      end
    end

    context "Less Than" do
      it "should work for less_than" do
        less_than_test = LessThanTest.new

        less_than_test.int_32_lt = 10
        less_than_test.float_32_lt = 20.5.to_f32

        less_than_test.int_32_lte = 52
        less_than_test.float_32_lte = 155.55.to_f32

        less_than_test.save

        less_than_test.errors.size.should eq 4
        less_than_test.errors[0].message.should eq "int_32_lt must be less than 10"
        less_than_test.errors[1].message.should eq "float_32_lt must be less than 20.5"
        less_than_test.errors[2].message.should eq "int_32_lte must be less than or equal to 50"
        less_than_test.errors[3].message.should eq "float_32_lte must be less than or equal to 100.25"

        less_than_test_nil = LessThanTest.new

        expect_raises(Exception, "Nil assertion failed") do
          less_than_test_nil.save
        end
      end
    end

    context "Greater Than" do
      it "should work for greater_than" do
        greater_than_test = GreaterThanTest.new

        greater_than_test.int_32_lt = 10
        greater_than_test.float_32_lt = 20.5.to_f32

        greater_than_test.int_32_lte = 49
        greater_than_test.float_32_lte = 100.20.to_f32

        greater_than_test.save

        greater_than_test.errors.size.should eq 4
        greater_than_test.errors[0].message.should eq "int_32_lt must be greater than 10"
        greater_than_test.errors[1].message.should eq "float_32_lt must be greater than 20.5"
        greater_than_test.errors[2].message.should eq "int_32_lte must be greater than or equal to 50"
        greater_than_test.errors[3].message.should eq "float_32_lte must be greater than or equal to 100.25"

        greater_than_test = GreaterThanTest.new

        expect_raises(Exception, "Nil assertion failed") do
          greater_than_test.save
        end
      end
    end

    context "Length" do
      it "should work for length" do
        length_test = LengthTest.new

        length_test.title = "one"
        length_test.description = "abcdefghijklmnopqrstuvwxyz"

        length_test.save

        length_test.errors.size.should eq 2
        length_test.errors[0].message.should eq "title is too short. It must be at least 5"
        length_test.errors[1].message.should eq "description is too long. It must be at most 25"
      end
    end

    context "Uniqueness" do
      Spec.before_each do
        PersonUniqueness.migrator.drop_and_create
      end

      it "should work for uniqueness" do
        person_uniqueness1 = PersonUniqueness.new
        person_uniqueness2 = PersonUniqueness.new

        person_uniqueness1.name = "awesomeName"
        person_uniqueness2.name = "awesomeName"

        person_uniqueness1.save
        person_uniqueness2.save

        person_uniqueness1.errors.size.should eq 0
        person_uniqueness2.errors.size.should eq 1

        person_uniqueness2.errors[0].message.should eq "name should be unique"
      end

      it "should work for uniqueness on the same instance" do
        person_uniqueness1 = PersonUniqueness.new

        person_uniqueness1.name = "awesomeName"
        person_uniqueness1.save

        person_uniqueness1.errors.size.should eq 0

        person_uniqueness1.name = "awesomeName"
        person_uniqueness1.save

        person_uniqueness1.errors.size.should eq 0
      end
    end
  end
{% end %}
