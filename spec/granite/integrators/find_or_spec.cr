require "../../spec_helper"

describe "find_or_create_by, find_or_initialize_by" do
  it "creates on find_or_create when not found" do
    Parent.clear
    Parent.find_or_create_by(name: "name")
    Parent.first!.name.should eq("name")
    Parent.first!.new_record?.should eq(false)
  end

  it "uses find on find_or_create_by when it exists" do
    Parent.clear
    Parent.create(name: "name")
    Parent.find_or_create_by(name: "name")
    Parent.count.should eq(1)
  end

  it "uses find on find_or_initialize_by when it exists" do
    Parent.clear
    Parent.create(name: "name")
    parent = Parent.find_or_initialize_by(name: "name")
    parent.new_record?.should eq(false)
  end

  it "initializes with find_or_initialize when not found" do
    Parent.clear
    parent = Parent.find_or_initialize_by(name: "gnome")
    parent.new_record?.should eq(true)
  end
end
