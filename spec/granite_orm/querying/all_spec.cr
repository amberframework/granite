require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id %}

  describe "Querying with {{ adapter.id }}" do
    describe "#all" do
      it "finds all the records" do
        model_ids = (0...100).map do |i|
          {{ model_constant }}.new(name: "model_#{i}").tap(&.save)
        end.map(&.id)

        all = {{ model_constant }}.all
        all.size.should eq model_ids.size
        all.map(&.id).compact.sort.should eq model_ids.compact
      end

      # TODO Fails under MySQL
      # it "finds records with numbered query substition" do
      #   name = "findable model"
      #   model = {{ model_constant }}.new(name: name).tap(&.save)
      #   set = {{ model_constant }}.all("WHERE name = $1", [name])
      #   set.size.should eq 1
      #   set.first.name.should eq name
      # end

      it "finds records with question mark substition" do
        name = "findable model"
        model = {{ model_constant }}.new(name: name).tap(&.save)
        set = {{ model_constant }}.all("WHERE name = ?", [name])
        set.size.should eq 1
        set.first.name.should eq name
      end
    end
  end

{% end %}
