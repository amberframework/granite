require "../../spec_helper"

describe "#find_by, #find_by!" do
  it "finds an object with a string field" do
    Parent.clear
    name = "robinson"

    model = Parent.new
    model.name = name
    model.save

    found = Parent.find_by(name: name)
    found.not_nil!.id.should eq model.id

    found = Parent.find_by!(name: name)
    found.should be_a(Parent)
  end

  it "works with multiple arguments" do
    Review.clear

    Review.create(name: "review1", upvotes: 2.to_i64)
    Review.create(name: "review2", upvotes: 0.to_i64)

    expected = Review.create(name: "review3", upvotes: 10.to_i64)

    Review.find_by(name: "review3", upvotes: 10).not_nil!.id.should eq expected.id

    expect_raises(Granite::Querying::NotFound, /No .*Review.* found where name = review1 and upvotes = 20/) do
      Review.find_by!(name: "review1", upvotes: 20)
    end
  end

  it "works with reserved words" do
    Parent.clear
    value = "robinson"

    model = ReservedWord.new
    model.all = value
    model.save

    found = ReservedWord.find_by(all: value)
    found.not_nil!.id.should eq model.id

    found = ReservedWord.find_by!(all: value)
    found.id.should eq model.id
  end

  it "returns nil or raises if no result" do
    Parent.clear
    found = Parent.find_by(name: "xxx")
    found.should be_nil

    expect_raises(Granite::Querying::NotFound, /No .*Parent.* found where name = xxx/) do
      Parent.find_by!(name: "xxx")
    end
  end
end
