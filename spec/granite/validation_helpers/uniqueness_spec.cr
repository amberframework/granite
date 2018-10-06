require "../../spec_helper"

describe Granite::ValidationHelpers do
  context "Uniqueness" do
    Spec.before_each do
      Validators::PersonUniqueness.migrator.drop_and_create
    end

    it "should work for uniqueness" do
      person_uniqueness1 = Validators::PersonUniqueness.new
      person_uniqueness2 = Validators::PersonUniqueness.new

      person_uniqueness1.name = "awesomeName"
      person_uniqueness2.name = "awesomeName"

      person_uniqueness1.save
      person_uniqueness2.save

      person_uniqueness1.errors.size.should eq 0
      person_uniqueness2.errors.size.should eq 1

      person_uniqueness2.errors[0].message.should eq "name should be unique"
    end

    it "should work for uniqueness on the same instance" do
      person_uniqueness1 = Validators::PersonUniqueness.new

      person_uniqueness1.name = "awesomeName"
      person_uniqueness1.save

      person_uniqueness1.errors.size.should eq 0

      person_uniqueness1.name = "awesomeName"
      person_uniqueness1.save

      person_uniqueness1.errors.size.should eq 0
    end
  end
end
