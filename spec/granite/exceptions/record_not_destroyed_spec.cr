require "../../spec_helper"

describe Granite::RecordNotDestroyed do
  it "should have a message" do
    parent = Parent.new
    parent.save

    Granite::RecordNotDestroyed
      .new(Parent.name, parent)
      .message
      .should eq("Could not destroy Parent: Name cannot be blank")
  end

  it "should have a model" do
    parent = Parent.new
    parent.save

    Granite::RecordNotDestroyed
      .new(Parent.name, parent)
      .model
      .should eq(parent)
  end
end
