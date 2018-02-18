require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #find" do
    it "finds an object by id" do
      model = Parent.new
      model.name = "Test Comment"
      model.save

      found = Parent.find model.id
      found.should_not be_nil
      found.not_nil!.id.should eq model.id
    end

    describe "with a custom primary key" do
      it "finds the object" do
        school = School.new
        school.name = "Test School"
        school.save
        primary_key = school.custom_id

        found_school = School.find primary_key
        found_school.should_not be_nil
      end
    end

    describe "with a modulized model" do
      it "finds the object" do
        county = Nation::County.new
        county.name = "Test County"
        county.save
        primary_key = county.id

        found_county = Nation::County.find primary_key
        found_county.should_not be_nil
      end
    end
  end
end
{% end %}
