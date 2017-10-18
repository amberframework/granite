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
    result = {"name" => "test todo", "priority" => 20, "created_at" => nil, "updated_at" => nil}

    t.to_h.should eq result
  end

  describe "#to_json" do
    it "converts object to json" do
      t = Todo.new(name: "test todo", priority: 20)
      result = %({"name":"test todo","priority":20,"created_at":null,"updated_at":null})

      t.to_json.should eq result
    end

    it "works with collections" do
      todos = [
        Todo.new(name: "todo 1", priority: 1),
        Todo.new(name: "todo 2", priority: 2),
        Todo.new(name: "todo 3", priority: 3),
      ]

      collection = JSON.parse todos.to_json
      collection[0].should eq({"name" => "todo 1", "priority" => 1, "created_at" => nil, "updated_at" => nil})
      collection[1].should eq({"name" => "todo 2", "priority" => 2, "created_at" => nil, "updated_at" => nil})
      collection[2].should eq({"name" => "todo 3", "priority" => 3, "created_at" => nil, "updated_at" => nil})
    end
  end
end
