require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #find_by" do
    it "finds an object with a string field" do
      name = "robinson"

      model = Parent.new
      model.name = name
      model.save

      found = Parent.find_by("name", name)
      found.not_nil!.id.should eq model.id
    end

    it "finds an object with a symbol field" do
      name = "robinson"

      model = Parent.new
      model.name = name
      model.save

      found = Parent.find_by(:name, name)
      found.not_nil!.id.should eq model.id
    end

    it "also works with reserved words" do
      value = "robinson"

      model = ReservedWord.new
      model.all = value
      model.save

      found = ReservedWord.find_by("all", value)
      found.not_nil!.id.should eq model.id

      found = ReservedWord.find_by(:all, value)
      found.not_nil!.id.should eq model.id
    end
  end
end
{% end %}
