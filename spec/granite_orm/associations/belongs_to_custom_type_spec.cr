require "../../spec_helper"

class Tool < Granite::ORM::Base
  adapter pg
  has_many :tool_reviews

  primary id : Int32
  field name : String

  def self.drop_and_create
    exec("DROP TABLE IF EXISTS tools;")
    exec("CREATE TABLE tools (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100)
      );
    ")
  end
end

class ToolReview < Granite::ORM::Base
  adapter pg
  belongs_to :tool, tool_id : Int32

  primary id : Int32
  field body : String

  def self.drop_and_create
    exec("DROP TABLE IF EXISTS tool_reviews;")
    exec("CREATE TABLE tool_reviews (
        id SERIAL PRIMARY KEY,
        tool_id INTEGER,
        body VARCHAR(100)
      );
    ")
  end
end

describe "belongs_to" do
  it "supports custom types for the join" do
    Tool.drop_and_create
    ToolReview.drop_and_create

    tool = Tool.new
    tool.name = "Screw driver"
    tool.save

    review = ToolReview.new
    review.tool = tool
    review.body = "Best tool ever!"
    review.save

    review.tool.name.should eq "Screw driver"
  end
end
