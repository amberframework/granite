require "../../spec_helper"

describe "#all" do
  it "finds all the records" do
    Parent.clear
    model_ids = (0...100).map do |i|
      Parent.new(name: "model_#{i}").tap(&.save)
    end.map(&.id)

    all = Parent.all
    all.size.should eq model_ids.size
    all.compact_map(&.id).sort!.should eq model_ids.compact
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
    Parent.new(name: name).save
    set = Parent.all("WHERE name = ?", [name])
    set.size.should eq 1
    set.first.name.should eq name
  end
end
