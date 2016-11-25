require "./spec_helper"
require "../src/adapter/mysql"

class Post < Kemalyst::Model
  adapter mysql
  sql_mapping({
    name:  ["VARCHAR(255)", String],
    body:  ["TEXT", String],
    total: ["INT", Int32],
    slug:  ["VARCHAR(255)", String],
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
      post.total = 10
      post.save
      post = Post.new
      post.name = "Test Post 2"
      post.save
      posts = Post.all
      posts.size.should eq 2
    end

    it "should get TEXT fields" do
      post = Post.new
      post.name = "Test Post"
      post.body = "Post Body"
      post.save

      posts = Post.all
      p1 = posts.first
      p1.body.should eq "Post Body"
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

    it "finds the post by field other than id" do
      post = Post.new
      post.slug = "test-slug-with-hypens"
      post.save
      slug = post.slug
      post = Post.find(slug, "slug")
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
