require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id %}

  describe "{{ adapter.id }} #find" do
    it "finds an object by id" do
      model = {{ model_constant }}.new
      model.name = "Test Comment"
      model.save

      found = {{ model_constant }}.find model.id
      found.should_not be_nil
      found.not_nil!.id.should eq model.id
    end
  end

{% end %}
