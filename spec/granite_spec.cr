require "./spec_helper"
require "../src/adapter/pg"

class Todo < Granite::Base
  adapter pg
  field name : String
  field priority : Int32
  timestamps
end

class Review < Granite::Base
  adapter pg
  field name : String
  field user_id : Int32
  field upvotes : Int64
  field sentiment : Float32
  field interest : Float64
  field published : Bool
  field created_at : Time
end

class WebSite < Granite::Base
  adapter pg
  primary custom_id : Int32
  field name : String

  validate :name, "Name cannot be blank", ->(s : WebSite) do
    !s.name.to_s.blank?
  end
end

describe Granite::Base do
  it "should create a new todo object with name set" do
    t = Todo.new(name: "Elorest")
    t.name.should eq "Elorest"
  end

  it "takes JSON::Any" do
    time_now = Time.now.at_beginning_of_second
    json_str = %({"name": "json::anyReview", "user_id": 99, "upvotes": 2, "sentiment": 1.23, "interest": 4.56, "published": true, "created_at": "#{time_now.to_s(Granite::DATETIME_FORMAT)}"})
    review_json = JSON.parse(json_str)

    review_json.is_a?(JSON::Any).should be_true

    review = Review.from_json(review_json).as(Review)
    review.name.should eq "json::anyReview"
    review.user_id.should eq 99_i32
    review.upvotes.should eq 2_i64
    review.sentiment.should eq 1.23_f32
    review.interest.should eq 4.56_f64
    review.published.should eq true
    review.created_at.should eq time_now
  end

  it "takes JSON::Any Array" do
    json_str = %([{"name": "web1"},{"name": "web2"},{"name": "web3"}])
    website_json = JSON.parse(json_str)

    website_json.is_a?(JSON::Any).should be_true

    web_sites = WebSite.from_json(website_json).as(Array(WebSite))

    web_sites[0].name.should eq "web1"
    web_sites[1].name.should eq "web2"
    web_sites[2].name.should eq "web3"
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

  describe "Granite::Settings.database_url" do
    it "should be set correctly" do
      Granite::Settings.database_url["mysql"] = "MYSQL_CONNECTION_URL"
      Granite::Settings.database_url["pg"] = "PG_CONNECTION_URL"
      Granite::Settings.database_url["sqlite"] = "SQLITE_CONNECTION_URL"

      urls = Granite::Settings.database_url

      urls["mysql"].should eq "MYSQL_CONNECTION_URL"
      urls["pg"].should eq "PG_CONNECTION_URL"
      urls["sqlite"].should eq "SQLITE_CONNECTION_URL"
    end
  end

  describe "validating fields" do
    context "without a name" do
      it "is not valid" do
        s = WebSite.new(name: "")
        s.valid?.should eq false
        s.errors.first.message.should eq "Name cannot be blank"
      end
    end

    context "when name is present" do
      it "is valid" do
        s = WebSite.new(name: "Hacker News")

        s.valid?.should eq true
        s.errors.empty?.should eq true
      end
    end
  end
end
