require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "Parent#{adapter.camelcase.id}".id %}

  describe "{{ adapter.id }} #first" do
    it "finds the first object" do
      first = {{ model_constant }}.new.tap do |model|
        model.name = "Test 1"
        model.save
      end

      second = {{ model_constant }}.new.tap do |model|
        model.name = "Test 2"
        model.save
      end

      found = {{ model_constant }}.first
      found.not_nil!.id.should eq first.id
    end

    it "supports a SQL clause" do
      first = {{ model_constant }}.new.tap do |model|
        model.name = "Test 1"
        model.save
      end

      second = {{ model_constant }}.new.tap do |model|
        model.name = "Test 2"
        model.save
      end

      found = {{ model_constant }}.first("ORDER BY id DESC")
      found.not_nil!.id.should eq second.id
    end

    it "returns nil if no result" do
      first = {{ model_constant }}.new.tap do |model|
        model.name = "Test 1"
        model.save
      end

      found = {{ model_constant }}.first("WHERE name = 'Test 2'")
      found.should be nil
    end
  end

{% end %}
