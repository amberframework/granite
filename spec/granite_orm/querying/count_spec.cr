require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "Parent#{adapter.camelcase.id}".id %}

  describe "{{ adapter.id }} #count" do
    it "returns 0 if no result" do
      count = {{ model_constant }}.count
      count.should eq 0
    end

    it "returns a number of the all records for the model" do
      2.times do |i|
        {{ model_constant }}.new(name: "model_#{i}").tap(&.save)
      end

      count = {{ model_constant }}.count
      count.should eq 2
    end
  end

{% end %}
