require "../../spec_helper"

describe "#update" do
  it "updates an object" do
    parent = Parent.new(name: "New Parent")
    parent.save!

    parent.update(name: "Other parent").should be_true
    parent.name.should eq "Other parent"

    Parent.find!(parent.id).name.should eq "Other parent"
  end

  it "does not update an invalid object" do
    parent = Parent.new(name: "New Parent")
    parent.save!

    parent.update(name: "").should be_false
    parent.name.should eq ""

    Parent.find!(parent.id).name.should eq "New Parent"
  end
end

describe "#update!" do
  it "updates an object" do
    parent = Parent.new(name: "New Parent")
    parent.save!

    parent.update!(name: "Other parent")
    parent.name.should eq "Other parent"

    Parent.find!(parent.id).name.should eq "Other parent"
  end

  it "does not update but raises an exception" do
    parent = Parent.new(name: "New Parent")
    parent.save!

    expect_raises(Granite::RecordNotSaved, "Parent") do
      parent.update!(name: "")
    end

    Parent.find!(parent.id).name.should eq "New Parent"
  end
end
