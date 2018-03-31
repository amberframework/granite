require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} .import" do
    it "should import 3 new objects" do
      to_import = [
        Parent.new(name: "ImportParent1"),
        Parent.new(name: "ImportParent2"),
        Parent.new(name: "ImportParent3"),
      ]
      Parent.import(to_import)
      Parent.all("WHERE name LIKE ?", ["Import%"]).size.should eq 3
    end
  end
end
{% end %}
