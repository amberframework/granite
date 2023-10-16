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

  context "when skip_timestamps is true" do
    it "does not update the created_at & updated_at fields" do
      time = Time.utc(2023, 9, 1)
      parent = Parent.create({name: "new parent"}, skip_timestamps: true)

      Parent.find!(parent.id).created_at.should be_nil
      Parent.find!(parent.id).updated_at.should be_nil
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

  context "when skip_timestamps is true" do
    it "does not update the created_at & updated_at fields" do
      time = Time.utc(2023, 9, 1)
      parent = Parent.create!({name: "new parent"}, skip_timestamps: true)

      Parent.find!(parent.id).created_at.should be_nil
      Parent.find!(parent.id).updated_at.should be_nil
    end
  end
end
