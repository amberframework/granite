require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    parent_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id
    school_constant = "GraniteExample::School#{adapter.camelcase.id}".id
    nation_county_constant = "GraniteExample::Nation::County#{adapter.camelcase.id}".id
  %}

  describe "{{ adapter.id }} #destroy" do
    it "destroys an object" do
      parent = {{ parent_constant }}.new
      parent.name = "Test Parent"
      parent.save

      id = parent.id
      parent.destroy
      found = {{ parent_constant }}.find id
      found.should be_nil
    end

    describe "with a custom primary key" do
      it "destroys an object" do
        school = {{ school_constant }}.new
        school.name = "Test School"
        school.save
        primary_key = school.custom_id
        school.destroy

        found_school = {{ school_constant }}.find primary_key
        found_school.should be_nil
      end
    end

    describe "with a modulized model" do
      it "destroys an object" do
        county = {{ nation_county_constant }}.new
        county.name = "Test County"
        county.save
        primary_key = county.id
        county.destroy

        found_county = {{ nation_county_constant }}.find primary_key
        found_county.should be_nil
      end
    end
  end

{% end %}
