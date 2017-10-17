require "./spec_helper"
require "../src/adapter/pg"

class Todo < Granite::ORM::Base
  adapter pg
  field name : String
  field priority : Int32
  timestamps
end

describe Granite::ORM::Base do
  it "should create a new todo object with name set" do
    t = Todo.new(name: "Elorest")
    t.name.should eq "Elorest"
  end

  it "should provide a to_h method" do
    t = Todo.new(name: "test todo", priority: 20)
    result = { "name" => "test todo", "priority": 20 }

    t.to_h.should eq result
  end

  it "should provide a to_json method" do
    t = Todo.new(name: "test todo", priority: 20)
    result = "{\"name\":\"test todo\",\"priority\":20}"

    t.to_json.should eq result
  end
end
