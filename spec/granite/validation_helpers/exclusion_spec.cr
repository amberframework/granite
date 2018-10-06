require "../../spec_helper"

describe Granite::ValidationHelpers do
  context "Exclusion" do
    it "should allow non reserved words" do
      exclusion = Validators::ExclusionTest.new
      exclusion.name = "none_conflicting"
      exclusion.save

      exclusion.errors.size.should eq 0
    end

    it "should disallow reservered words" do
      exclusion = Validators::ExclusionTest.new
      exclusion.name = "test_name"
      exclusion.save

      exclusion.errors.size.should eq 1
      exclusion.errors[0].message.should eq "Name got reserved values. Reserved values are test_name"
    end
  end
end
