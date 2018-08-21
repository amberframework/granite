require "../../spec_helper"

describe "#create" do
  it "creates a new object" do
    parent = Parent.create(name: "Test Parent")
    parent.persisted?.should be_true
    parent.name.should eq("Test Parent")
  end

  it "does not create an invalid object" do
    parent = Parent.create(name: "")
    parent.persisted?.should be_false
  end

  it "doesn't have a race condition on IDs" do
    channel = Channel(Int64).new

    2.times do
      spawn do
        parent = Parent.new(name: "Test Parent")
        parent.save
        channel.send(parent.id.not_nil!)
      end
    end

    id1 = channel.receive
    id2 = channel.receive

    id1.should_not eq id2
  end

  describe "with a custom primary key" do
    it "creates a new object" do
      school = School.create(name: "Test School")
      school.persisted?.should be_true
      school.name.should eq("Test School")
    end
  end

  describe "with a modulized model" do
    it "creates a new object" do
      county = Nation::County.create(name: "Test School")
      county.persisted?.should be_true
      county.name.should eq("Test School")
    end
  end

  describe "using a reserved word as a column name" do
    it "creates a new object" do
      reserved_word = ReservedWord.create(all: "foo")
      reserved_word.errors.empty?.should be_true
      reserved_word.all.should eq("foo")
    end
  end
end

describe "#create!" do
  it "creates a new object" do
    parent = Parent.create!(name: "Test Parent")
    parent.persisted?.should be_true
    parent.name.should eq("Test Parent")
  end

  it "does not save but raise an exception" do
    expect_raises(Granite::RecordNotSaved, "Parent") do
      Parent.create!(name: "")
    end
  end
end
