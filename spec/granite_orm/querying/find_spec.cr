require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #find?, #find" do
    it "finds an object by id" do
      model = Parent.new
      model.name = "Test Comment"
      model.save

      found = Parent.find? model.id
      found.should_not be_nil
      found.not_nil!.id.should eq model.id

      found = Parent.find model.id
      found.id.should eq model.id
    end

    describe "with a custom primary key" do
      it "finds the object" do
        school = School.new
        school.name = "Test School"
        school.save
        primary_key = school.custom_id

        found_school = School.find? primary_key
        found_school.should_not be_nil

        found_school = School.find primary_key
        found_school.should be_a(School)
      end
    end

    describe "with a modulized model" do
      it "finds the object" do
        county = Nation::County.new
        county.name = "Test County"
        county.save
        primary_key = county.id

        found_county = Nation::County.find? primary_key
        found_county.should_not be_nil

        found_county = Nation::County.find primary_key
        found_county.should be_a(Nation::County)
      end
    end

    it "returns nil or raises if no result" do
      found = Parent.find? 0
      found.should be_nil
      
      expect_raises(Granite::ORM::Querying::NotFound, /Couldn't find .*Parent.* with id=0/) do
        Parent.find 0
      end
    end
  end
end
{% end %}
