require "../../spec_helper"

describe "#find_by, #find_by!" do
  it "finds an object with a string field" do
    Parent.clear
    name = "robinson"

    model = Parent.new(name: name)
    model.save.should be_true

    found = Parent.find_by(name: name)
    if pa = found
      pa.id.should eq model.id
    else
      pa.should_not be_nil
    end

    found = Parent.find_by!(name: name)
    found.should be_a(Parent)
  end

  it "works with multiple arguments" do
    Review.clear

    Review.create(name: "review1", upvotes: 2.to_i64)
    Review.create(name: "review2", upvotes: 0.to_i64)

    expected = Review.create(name: "review3", upvotes: 10.to_i64)

    r = Review.find_by(name: "review3", upvotes: 10)
    if r
      r.id.should eq expected.id
    else
      r.should_not be_nil
    end

    expect_raises(Granite::Querying::NotFound, /No .*Review.* found where name = review1 and upvotes = 20/) do
      Review.find_by!(name: "review1", upvotes: 20)
    end
  end

  it "finds an object with nil value" do
    Student.clear

    model = Student.new
    model.save.should be_true

    found = Student.find_by(name: nil)
    if stu = found
      stu.id.should eq model.id
    else
      stu.should_not be_nil
    end

    found = Student.find_by!(name: nil)
    found.should be_a(Student)
  end

  it "works with reserved words" do
    Parent.clear
    value = "robinson"

    model = ReservedWord.new
    model.all = value
    model.save.should be_true

    found = ReservedWord.find_by(all: value)
    if rw = found
      rw.id.should eq model.id
    else
      rw.should_not be_nil
    end

    found = ReservedWord.find_by!(all: value)
    found.id.should eq model.id
  end

  it "finds an object when provided a hash" do
    Parent.clear
    name = "johnson"

    model = Parent.new(name: name)
    model.save.should be_true

    found = Parent.find_by({"name" => name})
    if pa = found
      pa.id.should eq model.id
    else
      pa.should_not be_nil
    end

    found = Parent.find_by!({"name" => name})
    found.should be_a(Parent)
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
