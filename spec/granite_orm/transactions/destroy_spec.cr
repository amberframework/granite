require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id %}

  describe "{{ adapter.id }} #destroy" do
    it "destroys an object" do
      model = {{ model_constant }}.new
      model.name = "Test User"
      model.save

      id = model.id
      model.destroy
      found = {{ model_constant }}.find id
      found.should be_nil
    end
  end

{% end %}
