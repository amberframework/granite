require "../../spec_helper"

describe Granite::ValidationHelpers do
  context "Choice" do
    it "should work for is_valid_choice" do
      choice_test = Validators::ChoiceTest.new

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
end
