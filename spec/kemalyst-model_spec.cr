require "./spec_helper"
require "../src/adapter/pg"

class Todo < Kemalyst::Model
  adapter pg
  field name : String
  timestamps

  def initialize(@name)
  end
end

describe Kemalyst::Model do
  it "should create a new todo object with name set" do
    t = Todo.new("Elorest")
    t.name.should eq "Elorest"
  end
end
