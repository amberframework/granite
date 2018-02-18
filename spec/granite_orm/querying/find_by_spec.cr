require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #find_by?, #find_by" do
    it "finds an object with a string field" do
      name = "robinson"

      model = Parent.new
      model.name = name
      model.save

      found = Parent.find_by?("name", name)
      found.not_nil!.id.should eq model.id

      found = Parent.find_by("name", name)
      found.should be_a(Parent)
    end

    it "finds an object with a symbol field" do
      name = "robinson"

      model = Parent.new
      model.name = name
      model.save

      found = Parent.find_by?(:name, name)
      found.not_nil!.id.should eq model.id

      found = Parent.find_by(:name, name)
      found.id.should eq model.id
    end

    it "also works with reserved words" do
      value = "robinson"

      model = ReservedWord.new
      model.all = value
      model.save

      found = ReservedWord.find_by?("all", value)
      found.not_nil!.id.should eq model.id

      found = ReservedWord.find_by(:all, value)
      found.id.should eq model.id
    end

    it "returns nil or raises if no result" do
      found = Parent.find_by?("name", "xxx")
      found.should be_nil

      expect_raises(Granite::ORM::Querying::NotFound, /Couldn't find .*Parent.* with name=xxx/) do
        Parent.find_by("name", "xxx")
      end
    end
  end
end
{% end %}
