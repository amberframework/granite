require "../../spec_helper"

describe Granite::ValidationHelpers do
  context "Nil" do
    it "should work for is_nil and not_nil for all data types" do
      nil_test = Validators::NilTest.new

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
end
