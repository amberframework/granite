require "../../spec_helper"

describe Granite::ValidationHelpers do
  context "Blank" do
    it "should work for is_blank and not_blank" do
      blank_test = Validators::BlankTest.new

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
end
