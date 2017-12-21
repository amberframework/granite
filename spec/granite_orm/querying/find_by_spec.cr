require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id %}

  describe "{{ adapter.id }} #find_by" do
    it "finds an object with a string field" do
      name = "robinson"

      model = {{ model_constant }}.new
      model.name = name
      model.save

      found = {{ model_constant }}.find_by("name", name)
      found.not_nil!.id.should eq model.id
    end

    it "finds an object with a symbol field" do
      name = "robinson"

      model = {{ model_constant }}.new
      model.name = name
      model.save

      found = {{ model_constant }}.find_by(:name, name)
      found.not_nil!.id.should eq model.id
    end
  end

{% end %}
