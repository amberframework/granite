require "./spec_helper"
require "../src/adapter/mysql"

class Post < Kemalyst::Model
  adapter mysql
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    body: ["TEXT", String]
  })
end

Post.drop
Post.create

describe Kemalyst::Adapter::Mysql do
  Spec.before_each do
    Post.clear
  end

  describe "#all" do
    it "finds all the posts" do
      post = Post.new
      post.name = "Test Post"
      post.save
      post = Post.new
      post.name = "Test Post 2"
      post.save
      posts = Post.all
      posts.size.should eq 2
    end
  end

  describe "#find" do
    it "finds the post by id" do
      post = Post.new
      post.name = "Test Post"
      post.save
      id = post.id
      post = Post.find id
      post.should_not be_nil 
    end
  end

  describe "#save" do
    it "creates a new post" do
      post = Post.new
      post.name = "Test Post"
      post.body = "Test Post"
      post.save
      post.id.should eq 1
    end

    it "updates an existing post" do
      post = Post.new
      post.name = "Test Post"
      post.save
      post.name = "Test Post 2"
      post.save
      post = Post.find 1
      if post
        post.name.should eq "Test Post 2"
      end
    end
  end

  describe "#destroy" do
    it "destroys a post" do
      post = Post.new
      post.name = "Test Post"
      post.save
      id = post.id
      post.destroy
      post = Post.find id
      post.should be_nil
    end
  end

end
