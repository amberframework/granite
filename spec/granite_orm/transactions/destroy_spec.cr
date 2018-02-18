require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #destroy" do
    it "destroys an object" do
      parent = Parent.new
      parent.name = "Test Parent"
      parent.save

      id = parent.id
      parent.destroy
      found = Parent.find? id
      found.should be_nil
    end

    describe "with a custom primary key" do
      it "destroys an object" do
        school = School.new
        school.name = "Test School"
        school.save
        primary_key = school.custom_id
        school.destroy

        found_school = School.find? primary_key
        found_school.should be_nil
      end
    end

    describe "with a modulized model" do
      it "destroys an object" do
        county = Nation::County.new
        county.name = "Test County"
        county.save
        primary_key = county.id
        county.destroy

        found_county = Nation::County.find? primary_key
        found_county.should be_nil
      end
    end
  end
end
{% end %}
