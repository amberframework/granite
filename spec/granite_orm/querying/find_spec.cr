require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    parent_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id
    school_constant = "GraniteExample::School#{adapter.camelcase.id}".id
  %}

  describe "{{ adapter.id }} #find" do
    it "finds an object by id" do
      model = {{ parent_constant }}.new
      model.name = "Test Comment"
      model.save

      found = {{ parent_constant }}.find model.id
      found.should_not be_nil
      found.not_nil!.id.should eq model.id
    end

    describe "with a custom primary key" do
      it "finds the object" do
        school = {{ school_constant }}.new
        school.name = "Test School"
        school.save
        primary_key = school.custom_id

        found_school = {{ school_constant }}.find primary_key
        found_school.should_not be_nil
      end
    end
  end

{% end %}
