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

    it "should handle nil values correctly for length validations" do
      length_test = Validators::LengthTest.new
      length_test.title = nil
      length_test.description = nil
      length_test.save

      # title being nil fails min length validation -> 1 error
      # description being nil passes max length validation -> 0 errors
      length_test.errors.size.should eq 1
      length_test.errors[0].message.should eq "title is too short. It must be at least 5"
    end
  end
end
