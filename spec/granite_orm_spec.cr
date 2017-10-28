require "./spec_helper"
require "../src/adapter/pg"

class Todo < Granite::ORM::Base
  adapter pg
  field name : String
  field priority : Int32
  timestamps
end

class Post < Granite::ORM::Base
  adapter pg
  field name : String
  field priority : Int32
  field published : Bool
  field upvotes : Int64
  field sentiment : Float32
  timestamps
end

class WebSite < Granite::ORM::Base
  adapter pg
  primary custom_id : Int32
  field name : String
end

describe Granite::ORM::Base do
  it "should create a new todo object with name set" do
    t = Todo.new(name: "Elorest")
    t.name.should eq "Elorest"
  end

  it "takes JSON::Type" do
    tmp_hash = {} of String | Symbol => String | JSON::Type
    body = %({
      name: "Elias",
      priotity: 333,
      published: false,
      upvotes: 9223372036854775807,
      sentiment: 3.143333333333
    })

    case json = JSON.parse_raw(body)
    when Hash
      json.each do |key, value|
        tmp_hash[key.as(String)] = value
      end
    when Array
      tmp_hash["_json"] = json
    end

    todo = Post.new(tmp_hash)
    todo.name.should eq "Elias"
    todo.priority.should eq 333
  end

  describe "#to_h" do
    it "convert object to hash" do
      t = Todo.new(name: "test todo", priority: 20)
      result = {"id" => nil, "name" => "test todo", "priority" => 20, "created_at" => nil, "updated_at" => nil}

      t.to_h.should eq result
    end

    it "honors custom primary key" do
      s = WebSite.new(name: "Hacker News")
      s.custom_id = 3
      s.to_h.should eq({"name" => "Hacker News", "custom_id" => 3})
    end
  end

  describe "#to_json" do
    it "converts object to json" do
      t = Todo.new(name: "test todo", priority: 20)
      result = %({"id":null,"name":"test todo","priority":20,"created_at":null,"updated_at":null})

      t.to_json.should eq result
    end

    it "works with collections" do
      todos = [
        Todo.new(name: "todo 1", priority: 1),
        Todo.new(name: "todo 2", priority: 2),
        Todo.new(name: "todo 3", priority: 3),
      ]

      collection = JSON.parse todos.to_json
      collection[0].should eq({"id" => nil, "name" => "todo 1", "priority" => 1, "created_at" => nil, "updated_at" => nil})
      collection[1].should eq({"id" => nil, "name" => "todo 2", "priority" => 2, "created_at" => nil, "updated_at" => nil})
      collection[2].should eq({"id" => nil, "name" => "todo 3", "priority" => 3, "created_at" => nil, "updated_at" => nil})
    end

    it "honors custom primary key" do
      s = WebSite.new(name: "Hacker News")
      s.custom_id = 3
      s.to_json.should eq %({"custom_id":3,"name":"Hacker News"})
    end
  end
end
