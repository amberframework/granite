require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #all" do
    it "finds all the records" do
      model_ids = (0...100).map do |i|
        Parent.new(name: "model_#{i}").tap(&.save)
      end.map(&.id)

      all = Parent.all
      all.size.should eq model_ids.size
      all.map(&.id).compact.sort.should eq model_ids.compact
    end

    # TODO Fails under MySQL
    # it "finds records with numbered query substition" do
    #   name = "findable model"
    #   model = Parent.new(name: name).tap(&.save)
    #   set = Parent.all("WHERE name = $1", [name])
    #   set.size.should eq 1
    #   set.first.name.should eq name
    # end

    it "finds records with question mark substition" do
      name = "findable model"
      model = Parent.new(name: name).tap(&.save)
      set = Parent.all("WHERE name = ?", [name])
      set.size.should eq 1
      set.first.name.should eq name
    end
  end
end
{% end %}
