require "../../spec_helper"

class NilTest < Granite::Base
  adapter mysql

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
  adapter pg

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
  adapter sqlite

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
  adapter mysql

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
  adapter pg

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
  adapter sqlite

  field title : String
  field description : String

  validate_min_length :title, 5
  validate_max_length :description, 25
end

class PersonUniqueness < Granite::Base
  adapter pg

  field name : String

  validate_uniqueness :name
end

PersonUniqueness.migrator.drop_and_create

describe Granite::ValidationHelpers do
  context "Nil" do
    it "should work for is_nil and not_nil for all data types" do
      nilTest = NilTest.new

      nilTest.first_name = "John"
      nilTest.last_name = "Smith"
      nilTest.age = 32
      nilTest.born = true
      nilTest.value = 123.56.to_f32

      nilTest.save

      nilTest.errors.size.should eq 10
      nilTest.errors[0].message.should eq "first_name_not_nil must not be nil"
      nilTest.errors[1].message.should eq "last_name_not_nil must not be nil"
      nilTest.errors[2].message.should eq "age_not_nil must not be nil"
      nilTest.errors[3].message.should eq "born_not_nil must not be nil"
      nilTest.errors[4].message.should eq "value_not_nil must not be nil"
      nilTest.errors[5].message.should eq "first_name must be nil"
      nilTest.errors[6].message.should eq "last_name must be nil"
      nilTest.errors[7].message.should eq "age must be nil"
      nilTest.errors[8].message.should eq "born must be nil"
      nilTest.errors[9].message.should eq "value must be nil"
    end
  end

  context "Blank" do
    it "should work for is_blank and not_blank" do
      blankTest = BlankTest.new

      blankTest.first_name_not_blank = ""
      blankTest.last_name_not_blank = "      "

      blankTest.first_name_is_blank = "foo"
      blankTest.last_name_is_blank = "  bar  "

      blankTest.save

      blankTest.errors.size.should eq 4
      blankTest.errors[0].message.should eq "first_name_not_blank must not be blank"
      blankTest.errors[1].message.should eq "last_name_not_blank must not be blank"
      blankTest.errors[2].message.should eq "first_name_is_blank must be blank"
      blankTest.errors[3].message.should eq "last_name_is_blank must be blank"
    end
  end

  context "Choice" do
    it "should work for is_valid_choice" do
      choiceTest = ChoiceTest.new

      choiceTest.number_symbol = 4
      choiceTest.type_array_symbol = "foo"

      choiceTest.number_string = 2
      choiceTest.type_array_string = "bar"

      choiceTest.save

      choiceTest.errors.size.should eq 4
      choiceTest.errors[0].message.should eq "number_symbol has an invalid choice. Valid choices are: 1,2,3"
      choiceTest.errors[1].message.should eq "type_array_symbol has an invalid choice. Valid choices are: internal,external,third_party"
      choiceTest.errors[2].message.should eq "number_string has an invalid choice. Valid choices are: 4,5,6"
      choiceTest.errors[3].message.should eq "type_array_string has an invalid choice. Valid choices are: internal,external,third_party"
    end
  end

  context "Less Than" do
    it "should work for less_than" do
      lessThanTest = LessThanTest.new

      lessThanTest.int_32_lt = 10
      lessThanTest.float_32_lt = 20.5.to_f32

      lessThanTest.int_32_lte = 52
      lessThanTest.float_32_lte = 155.55.to_f32

      lessThanTest.save

      lessThanTest.errors.size.should eq 4
      lessThanTest.errors[0].message.should eq "int_32_lt must be less than 10"
      lessThanTest.errors[1].message.should eq "float_32_lt must be less than 20.5"
      lessThanTest.errors[2].message.should eq "int_32_lte must be less than or equal to 50"
      lessThanTest.errors[3].message.should eq "float_32_lte must be less than or equal to 100.25"

      lessThanTestNil = LessThanTest.new

      expect_raises(Exception, "Nil assertion failed") do
        lessThanTestNil.save
      end
    end
  end

  context "Greater Than" do
    it "should work for greater_than" do
      greaterThanTest = GreaterThanTest.new

      greaterThanTest.int_32_lt = 10
      greaterThanTest.float_32_lt = 20.5.to_f32

      greaterThanTest.int_32_lte = 49
      greaterThanTest.float_32_lte = 100.20.to_f32

      greaterThanTest.save

      greaterThanTest.errors.size.should eq 4
      greaterThanTest.errors[0].message.should eq "int_32_lt must be greater than 10"
      greaterThanTest.errors[1].message.should eq "float_32_lt must be greater than 20.5"
      greaterThanTest.errors[2].message.should eq "int_32_lte must be greater than or equal to 50"
      greaterThanTest.errors[3].message.should eq "float_32_lte must be greater than or equal to 100.25"

      greaterThanTest = GreaterThanTest.new

      expect_raises(Exception, "Nil assertion failed") do
        greaterThanTest.save
      end
    end
  end

  context "Length" do
    it "should work for length" do
      lengthTest = LengthTest.new

      lengthTest.title = "one"
      lengthTest.description = "abcdefghijklmnopqrstuvwxyz"

      lengthTest.save

      lengthTest.errors.size.should eq 2
      lengthTest.errors[0].message.should eq "title is too short. It must be at least 5"
      lengthTest.errors[1].message.should eq "description is too long. It must be at most 25"
    end
  end

  context "Uniqueness" do
    it "should work for uniqueness" do
      personUniqueness1 = PersonUniqueness.new
      personUniqueness2 = PersonUniqueness.new

      personUniqueness1.name = "awesomeName"
      personUniqueness2.name = "awesomeName"

      personUniqueness1.save
      personUniqueness2.save

      personUniqueness1.errors.size.should eq 0
      personUniqueness2.errors.size.should eq 1

      personUniqueness2.errors[0].message.should eq "name should be unique"

      # Should be valid because it should not check uniqueness on itself
      personUniqueness1.save
      personUniqueness1.errors.size.should eq 0
    end
  end
end
