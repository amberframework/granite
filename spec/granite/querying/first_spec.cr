require "../../spec_helper"

describe "#first, #first!" do
  it "finds the first object" do
    Parent.clear
    first = Parent.new.tap do |model|
      model.name = "Test 1"
      model.save
    end

    Parent.new.tap do |model|
      model.name = "Test 2"
      model.save
    end

    found = Parent.first
    found.not_nil!.id.should eq first.id

    found = Parent.first!
    found.id.should eq first.id
  end

  it "supports a SQL clause" do
    Parent.clear
    Parent.new.tap do |model|
      model.name = "Test 1"
      model.save
    end

    second = Parent.new.tap do |model|
      model.name = "Test 2"
      model.save
    end

    found = Parent.first("ORDER BY id DESC")
    found.not_nil!.id.should eq second.id

    found = Parent.first!("ORDER BY id DESC")
    found.id.should eq second.id
  end

  it "returns nil or raises if no result" do
    Parent.clear
    Parent.new.tap do |model|
      model.name = "Test 1"
      model.save
    end

    found = Parent.first("WHERE name = 'Test 2'")
    found.should be nil

    expect_raises(Granite::Querying::NotFound, /No .*Parent.* found with first\(WHERE name = 'Test 2'\)/) do
      Parent.first!("WHERE name = 'Test 2'")
    end
  end
end
