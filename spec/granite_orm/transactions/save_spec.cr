require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #save" do
    it "creates a new object" do
      parent = Parent.new
      parent.name = "Test Parent"
      parent.save
      parent.id.should_not be_nil
    end

    it "does not create an invalid object" do
      parent = Parent.new
      parent.name = ""
      parent.save
      parent.id?.should be_nil
    end

    it "updates an existing object" do
      parent = Parent.new
      parent.name = "Test Parent"
      parent.save
      parent.name = "Test Parent 2"
      parent.save

      parents = Parent.all
      parents.size.should eq 1

      found = Parent.first
      found.name.should eq parent.name
    end

    it "does not update an invalid object" do
      parent = Parent.new
      parent.name = "Test Parent"
      parent.save
      parent.name = ""
      parent.save
      parent = Parent.find parent.id
      parent.name.should eq "Test Parent"
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

        found_school = School.find primary_key
        found_school.custom_id.should eq primary_key
        found_school.name.should eq new_name
      end
    end

    describe "with a modulized model" do
      it "creates a new object" do
        county = Nation::County.new
        county.name = "Test School"
        county.save
        county.id.should_not be_nil
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

        found_county = Nation::County.find primary_key
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
end
{% end %}
