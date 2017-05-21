require "./spec_helper"
require "../src/adapter/pg"

class Todo < Granite::ORM
  adapter pg
  field name : String
  timestamps
end

describe Granite::ORM do
  it "should create a new todo object with name set" do
    t = Todo.new(name: "Elorest")
    t.name.should eq "Elorest"
  end
end
