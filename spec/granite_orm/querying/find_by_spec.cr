require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "Parent#{adapter.camelcase.id}".id %}
  {% reserved_word_constant = "ReservedWord#{adapter.camelcase.id}".id %}

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

    it "also works with reserved words" do
      value = "robinson"

      model = {{ reserved_word_constant }}.new
      model.all = value
      model.save

      found = {{ reserved_word_constant }}.find_by("all", value)
      found.not_nil!.id.should eq model.id

      found = {{ reserved_word_constant }}.find_by(:all, value)
      found.not_nil!.id.should eq model.id
    end
  end

{% end %}
