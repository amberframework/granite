require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} belongs_to" do
    it "supports custom types for the join" do
      tool = Tool.new
      tool.name = "Screw driver"
      tool.save

      review = ToolReview.new
      review.tool = tool
      review.body = "Best tool ever!"
      review.save

      review.tool.name.should eq "Screw driver"
    end
  end
end
{% end %}
