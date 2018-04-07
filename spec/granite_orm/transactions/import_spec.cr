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

    it "should work with on_duplicate_key_update" do
      to_import = [
         Parent.new(id: 111, name: "ImportParent1"),
         Parent.new(id: 112, name: "ImportParent2"),
         Parent.new(id: 113, name: "ImportParent3"),
      ]

      Parent.import(to_import)

      to_import = [
         Parent.new(id: 112, name: "ImportParent112"),
      ]

      Parent.import(to_import, on_duplicate_key_update: ["name"])

      if parent = Parent.find 112
        parent.name.should be "ImportParent112"
				parent.id.should eq 112
			end
		end

    it "should work with on_duplicate_key_ignore" do
      to_import = [
         Parent.new(id: 111, name: "ImportParent1"),
         Parent.new(id: 112, name: "ImportParent2"),
         Parent.new(id: 113, name: "ImportParent3"),
      ]

      Parent.import(to_import)

      to_import = [
         Parent.new(id: 113, name: "ImportParent113"),
      ]

      Parent.import(to_import, on_duplicate_key_ignore: true)

      if parent = Parent.find 113
        parent.name.should be "ImportParent3"
				parent.id.should eq 113
      end
    end
	end
end
{% end %}
