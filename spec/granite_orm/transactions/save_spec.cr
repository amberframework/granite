require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    parent_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id
    school_constant = "GraniteExample::School#{adapter.camelcase.id}".id
    nation_county_constant = "GraniteExample::Nation::County#{adapter.camelcase.id}".id
  %}

  describe "{{ adapter.id }} #save" do
    it "creates a new object" do
      parent = {{ parent_constant }}.new
      parent.name = "Test Parent"
      parent.save
      parent.id.should_not be_nil
    end

    it "updates an existing object" do
      parent = {{ parent_constant }}.new
      parent.name = "Test Parent"
      parent.save
      parent.name = "Test Parent 2"
      parent.save

      parents = {{ parent_constant }}.all
      parents.size.should eq 1

      found = {{ parent_constant }}.first
      found.not_nil!.name.should eq parent.name
    end

    describe "with a custom primary key" do
      it "creates a new object" do
        school = {{ school_constant }}.new
        school.name = "Test School"
        school.save
        school.custom_id.should_not be_nil
      end

      it "updates an existing object" do
        old_name = "Test School 1"
        new_name = "Test School 2"

        school = {{ school_constant }}.new
        school.name = old_name
        school.save

        primary_key = school.custom_id

        school.name = new_name
        school.save

        found_school = {{ school_constant }}.find primary_key
        found_school.not_nil!.custom_id.should eq primary_key
        found_school.not_nil!.name.should eq new_name
      end
    end

    describe "with a modulized model" do
      it "creates a new object" do
        county = {{ nation_county_constant }}.new
        county.name = "Test School"
        county.save
        county.id.should_not be_nil
      end

      it "updates an existing object" do
        old_name = "Test County 1"
        new_name = "Test County 2"

        county = {{ nation_county_constant }}.new
        county.name = old_name
        county.save

        primary_key = county.id

        county.name = new_name
        county.save

        found_county = {{ nation_county_constant }}.find primary_key
        found_county.not_nil!.name.should eq new_name
      end
    end
  end

{% end %}
