require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe Granite::RecordNotSaved do
    it "should have a message" do
      parent = Parent.new
      parent.save

      Granite::RecordNotSaved
        .new(Parent.name, parent)
        .message
        .should eq("Could not process {{adapter.capitalize.id}}::Parent")
    end

    it "should have a model" do
      parent = Parent.new
      parent.save

      Granite::RecordNotSaved
        .new(Parent.name, parent)
        .model
        .should eq(parent)
    end
  end
end
{% end %}
