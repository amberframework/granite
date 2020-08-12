require "../../spec_helper"

describe "#save" do
  it "creates a new object" do
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save
    parent.persisted?.should be_true
  end

  it "does not create an invalid object" do
    parent = Parent.new
    parent.name = ""
    parent.save
    parent.persisted?.should be_false
  end

  it "create an invalid object with validation disabled" do
    parent = Parent.new
    parent.name = ""
    parent.save(validate: false)
    parent.persisted?.should be_true
  end

  it "does not create an invalid object with validation explicitly enabled" do
    parent = Parent.new
    parent.name = ""
    parent.save(validate: true)
    parent.persisted?.should be_false
  end

  it "does not save a model with type conversion errors" do
    model = Comment.new(articleid: "foo")
    model.errors.size.should eq 1
    model.save.should be_false
  end

  it "updates an existing object" do
    Parent.clear
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save
    parent.name = "Test Parent 2"
    parent.save

    parents = Parent.all
    parents.size.should eq 1

    found = Parent.first!
    found.name.should eq parent.name
  end

  it "does not update an invalid object" do
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save
    parent.name = ""
    parent.save
    parent = Parent.find! parent.id
    parent.name.should eq "Test Parent"
  end

  it "update an invalid object with validation disabled" do
    Parent.clear
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save
    parent.name = ""
    parent.save(validate: false)

    parents = Parent.all
    parents.size.should eq 1

    found = Parent.first!
    found.name.should eq parent.name
  end

  it "does not update an invalid object with validation explicitly enabled" do
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save
    parent.name = ""
    parent.save(validate: true)
    parent = Parent.find! parent.id
    parent.name.should eq "Test Parent"
  end

  it "does not update when the conflicted primary key is given to the new record" do
    parent1 = Parent.new
    parent1.name = "Test Parent"
    parent1.save.should be_true

    parent2 = Parent.new
    parent2.id = parent1.id
    parent2.name = "Test Parent2"
    parent2.save.should be_false
  end

  describe "with a custom primary key" do
    it "creates a new object" do
      school = School.new
      school.name = "Test School"
      school.save
      school.custom_id.should_not be_nil
    end

    it "updates an existing object" do
      old_name = "Test School 1"
      new_name = "Test School 2"

      school = School.new
      school.name = old_name
      school.save

      primary_key = school.custom_id

      school.name = new_name
      school.save

      found_school = School.find! primary_key
      found_school.custom_id.should eq primary_key
      found_school.name.should eq new_name
    end

    it "updates states of new_record and persisted" do
      parent = Parent.new
      parent.new_record?.should be_true
      parent.persisted?.should be_false

      parent.name = "Test Parent"
      parent.save
      parent.new_record?.should be_false
      parent.persisted?.should be_true
    end
  end

  describe "with a modulized model" do
    it "creates a new object" do
      county = Nation::County.new
      county.name = "Test School"
      county.save
      county.persisted?.should be_true
    end

    it "updates an existing object" do
      old_name = "Test County 1"
      new_name = "Test County 2"

      county = Nation::County.new
      county.name = old_name
      county.save

      primary_key = county.id

      county.name = new_name
      county.save

      found_county = Nation::County.find! primary_key
      found_county.name.should eq new_name
    end
  end

  describe "using a reserved word as a column name" do
    # `all` is a reserved word in almost RDB like MySQL, PostgreSQL
    it "creates and updates" do
      reserved_word = ReservedWord.new
      reserved_word.all = "foo"
      reserved_word.save
      reserved_word.errors.empty?.should be_true

      reserved_word.all = "bar"
      reserved_word.save
      reserved_word.errors.empty?.should be_true
      reserved_word.all.should eq("bar")
    end
  end
end

describe "#save!" do
  it "creates a new object" do
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save!
    parent.persisted?.should be_true
  end

  it "does not create but raise an exception" do
    parent = Parent.new

    expect_raises(Granite::RecordNotSaved, "Parent") do
      parent.save!
    end
  end
end
