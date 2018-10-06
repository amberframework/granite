require "../../spec_helper"

describe Granite::ValidationHelpers do
  context "Less Than" do
    it "should work for less_than" do
      less_than_test = Validators::LessThanTest.new

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

      less_than_test_nil = Validators::LessThanTest.new

      expect_raises(Exception, "Nil assertion failed") do
        less_than_test_nil.save
      end
    end
  end

  context "Greater Than" do
    it "should work for greater_than" do
      greater_than_test = Validators::GreaterThanTest.new

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

      greater_than_test = Validators::GreaterThanTest.new

      expect_raises(Exception, "Nil assertion failed") do
        greater_than_test.save
      end
    end
  end
end
