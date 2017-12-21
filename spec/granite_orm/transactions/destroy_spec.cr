require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    parent_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id
    school_constant = "GraniteExample::School#{adapter.camelcase.id}".id
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
  end

{% end %}
