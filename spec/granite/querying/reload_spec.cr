require "../../spec_helper"

describe "#reload" do
  before_each do
    Parent.clear
  end

  it "reloads the record from the database" do
    parent = Parent.create(name: "Parent")

    Parent.find!(parent.id).update(name: "Other")

    parent.reload.name.should eq "Other"
  end

  it "raises an error if the record no longer exists" do
    parent = Parent.create(name: "Parent")
    parent.destroy

    expect_raises(Granite::Querying::NotFound) do
      parent.reload
    end
  end
end
