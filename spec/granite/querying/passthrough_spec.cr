require "../../spec_helper"

describe "#query" do
  it "calls query against the db driver" do
    Parent.clear
    Parent.query "SELECT name FROM parents" do |rs|
      rs.column_name(0).should eq "name"
    end
  end
end

describe "#scalar" do
  it "calls scalar against the db driver" do
    Parent.clear
    Parent.scalar "SELECT count(*) FROM parents" do |total|
      total.should eq 0
    end
  end
end
