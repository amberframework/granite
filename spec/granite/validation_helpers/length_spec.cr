require "../../spec_helper"

describe Granite::ValidationHelpers do
  context "Length" do
    it "should work for length" do
      length_test = Validators::LengthTest.new

      length_test.title = "one"
      length_test.description = "abcdefghijklmnopqrstuvwxyz"

      length_test.save

      length_test.errors.size.should eq 2
      length_test.errors[0].message.should eq "title is too short. It must be at least 5"
      length_test.errors[1].message.should eq "description is too long. It must be at most 25"
    end
  end
end
