require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #query" do
    it "calls query against the db driver" do
     Parent.clear
     Parent.query "SELECT name FROM parents" do |rs|
        rs.column_name(0).should eq "name"
       end
    end
  end

  describe "{{ adapter.id }} #scalar" do
    it "calls scalar against the db driver" do
     Parent.clear
     Parent.scalar "SELECT count(*) FROM parents" do |total|
       total.should eq 0
     end
    end
  end
end
{% end %}
