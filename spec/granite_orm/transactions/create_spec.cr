require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} .create" do
    it "creates a new object" do
      parent = Parent.create(name: "Test Parent")
      parent.id.should_not be_nil
      parent.name.should eq("Test Parent")
    end

    it "does not create an invalid object" do
      parent = Parent.create(name: "")
      parent.id.should be_nil
    end

    describe "with a custom primary key" do
      it "creates a new object" do
        school = School.create(name: "Test School")
        school.custom_id.should_not be_nil
        school.name.should eq("Test School")
      end
    end

    describe "with a modulized model" do
      it "creates a new object" do
        county = Nation::County.create(name: "Test School")
        county.id.should_not be_nil
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
end
{% end %}
