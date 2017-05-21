require "./spec_helper"
require "../src/adapter/mysql"

class Post < Granite::ORM
  adapter mysql
  field name : String
  field body : String
  field total : Int32
  field slug : String
  timestamps
end

class Site < Granite::ORM
  adapter mysql
  primary custom_id : Int32
  field name : String
end

class Chat::Room < Granite::ORM
  adapter mysql
  field name : String
end

Post.exec("DROP TABLE IF EXISTS posts;")
Post.exec("CREATE TABLE posts (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255),
  body TEXT,
  total INTEGER,
  slug VARCHAR(255),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  PRIMARY KEY (id)
);
")

Site.exec("DROP TABLE IF EXISTS sites;")
Site.exec("CREATE TABLE sites (
  custom_id INT(11) NOT NULL AUTO_INCREMENT,
  name VARCHAR(255),
  PRIMARY KEY (custom_id)
);
")

Chat::Room.exec("DROP TABLE IF EXISTS chat_rooms;")
Chat::Room.exec("CREATE TABLE chat_rooms (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255),
  PRIMARY KEY (id)
);
")

describe Granite::Adapter::Mysql do
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
  end

  describe "#find_by" do
    it "finds the post by field" do
      post = Post.new
      post.slug = "test-slug-with-hypens"
      post.save
      slug = post.slug
      post = Post.find_by("slug", slug)
      post.should_not be_nil
    end

    it "finds the post by field using a symbol" do
      post = Post.new
      post.slug = "test-slug-with-hypens"
      post.save
      slug = post.slug
      post = Post.find_by(:slug, slug)
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

  describe "Site model with custom primary key" do
    Spec.before_each do
      Site.clear
    end

    describe "#find" do
      it "finds the site by custom_id" do
        site = Site.new
        site.name = "Test Site"
        site.save
        pk = site.custom_id
        site = Site.find pk
        site.should_not be_nil
      end
    end

    describe "#save" do
      it "updates an existing site" do
        site = Site.new
        site.name = "Test Site"
        site.save
        site.name = "Test Site 2"
        site.save
        site = Site.find 1
        if site
          site.name.should eq "Test Site 2"
        end
      end
    end

    describe "#destroy" do
      it "destroys a site" do
        site = Site.new
        site.name = "Test Site"
        site.save
        pk = site.custom_id
        site.destroy
        site = Site.find pk
        site.should be_nil
      end
    end
  end

  describe "Chat::Room using module" do
    Spec.before_each do
      Chat::Room.clear
    end

    describe "#find" do
      it "finds the Chat::Room" do
        chat_room = Chat::Room.new
        chat_room.name = "Test Room"
        chat_room.save
        pk = chat_room.id
        chat_room = Chat::Room.find pk
        chat_room.should_not be_nil
      end
    end

    describe "#save" do
      it "updates an existing Chat::Room" do
        chat_room = Chat::Room.new
        chat_room.name = "Test Site"
        chat_room.save
        chat_room.name = "Test Site 2"
        chat_room.save
        chat_room = Chat::Room.find 1
        if chat_room
          chat_room.name.should eq "Test Site 2"
        end
      end
    end

    describe "#destroy" do
      it "destroys a Chat::Room" do
        chat_room = Chat::Room.new
        chat_room.name = "Test Site"
        chat_room.save
        pk = chat_room.id
        chat_room.destroy
        chat_room = Site.find pk
        chat_room.should be_nil
      end
    end
  end

end
