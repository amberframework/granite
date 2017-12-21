require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id %}

  describe "Saving with {{ adapter.id }}" do
    describe "#save" do
      it "creates a new object" do
        model = {{ model_constant }}.new
        model.name = "Test Comment"
        model.save
        model.id.should_not be_nil
      end

      it "updates an existing object" do
        model = {{ model_constant }}.new
        model.name = "Test Comment"
        model.save
        model.name = "Test Comment 2"
        model.save

        models = {{ model_constant }}.all
        models.size.should eq 1

        found = {{ model_constant }}.first
        found.not_nil!.name.should eq model.name
      end
    end
  end

{% end %}
