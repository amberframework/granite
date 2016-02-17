require "spec"
require "../src/mysql_adapter"
include Amethyst::Model

class Post < Model
  adapter mysql
  sql_mapping({ 
    name: "VARCHAR(255)", 
    body: "TEXT" 
  })
end

class PostsByMonth < RoModel
  adapter mysql
  sql_mapping({ 
    month: "MONTHNAME(created_at)", 
    total: "COUNT(*)" 
  }, "posts")
end

Post.drop
Post.create

describe "Read Only Model" do
  Spec.before_each do
    Post.clear
  end

  describe "#all" do
    it "should find all the months and counts for posts" do
      post = Post.new
      post.name = "Test Post"
      post.save
      post = Post.new
      post.name = "Test Post 2"
      post.save
      posts_by_month = PostsByMonth.all("GROUP BY MONTH(created_at)")
      posts_by_month[0].total.should eq 2
    end
  end
end

