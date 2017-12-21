require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    parent_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id
    school_constant = "GraniteExample::School#{adapter.camelcase.id}".id
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
  end

{% end %}
