require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #count" do
    it "returns 0 if no result" do
      Parent.clear
      count = Parent.count
      count.should eq 0
    end

    it "returns a number of the all records for the model" do
      count = Parent.count
      2.times do |i|
        Parent.new(name: "model_#{i}").tap(&.save)
      end

      (Parent.count - count).should eq 2
    end
  end
end
{% end %}
