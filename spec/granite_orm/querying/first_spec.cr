require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #first" do
    it "finds the first object" do
      first = Parent.new.tap do |model|
        model.name = "Test 1"
        model.save
      end

      second = Parent.new.tap do |model|
        model.name = "Test 2"
        model.save
      end

      found = Parent.first
      found.not_nil!.id.should eq first.id
    end

    it "supports a SQL clause" do
      first = Parent.new.tap do |model|
        model.name = "Test 1"
        model.save
      end

      second = Parent.new.tap do |model|
        model.name = "Test 2"
        model.save
      end

      found = Parent.first("ORDER BY id DESC")
      found.not_nil!.id.should eq second.id
    end

    it "returns nil if no result" do
      first = Parent.new.tap do |model|
        model.name = "Test 1"
        model.save
      end

      found = Parent.first("WHERE name = 'Test 2'")
      found.should be nil
    end
  end
end
{% end %}
