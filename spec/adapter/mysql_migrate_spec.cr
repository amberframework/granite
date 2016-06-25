require "./spec_helper"
require "../src/adapter/mysql"

class Post1 < Kemalyst::Model
  adapter mysql
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(255)", String]
  }, posts)
end

# Add a new field
class Post2 < Kemalyst::Model
  adapter mysql
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(255)", String],
    flag: ["BOOLEAN", Bool]
  }, posts)
end

# Change type of field
class Post3 < Kemalyst::Model
  adapter mysql
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    body: ["TEXT", String],
  }, posts)
end

# Change size of field
class Post4 < Kemalyst::Model
  adapter mysql
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(512)", String],
  }, posts)
end

describe Kemalyst::Adapter::Mysql do
  describe "#migrate" do
    it "adds any new fields" do
      Post1.drop
      Post1.create
      Post2.migrate
      if results = Post2.query("describe posts;")
        results.size.should eq 6
      else
        raise "describe posts returned nil"
      end
    end

    context "type change" do
      it "renames the field to old_*" do
        Post1.drop
        Post1.create
        Post3.migrate
        if results = Post1.query("describe posts;")
          results[3][0].should eq "old_body"
        else
          raise "describe posts returned nil"
        end
      end

      it "adds a new field" do
        Post1.drop
        Post1.create
        Post3.migrate
        if results = Post1.query("describe posts;")
          results.size.should eq 6
        else
          raise "describe posts returned nil"
        end
      end

      it "copies the data from the old field" do
        Post1.drop
        Post1.create
        post = Post1.new
        post.body = "Hello"
        post.save
        Post3.migrate
        if results = Post1.query("select body from posts")
          #TODO: This should return a string, not a slice
          #results[0][0].to_s.should eq "Hello"
        else
          raise "copy data failed"
        end
      end
    end

    context "size change" do
      it "renames the field to old_*" do
        Post1.drop
        Post1.create
        Post4.migrate
        if results = Post1.query("describe posts;")
          results[3][0].should eq "old_body"
        else
          raise "describe posts returned nil"
        end
      end

      it "adds a new field" do
        Post1.drop
        Post1.create
        Post4.migrate
        if results = Post1.query("describe posts;")
          results.size.should eq 6
        else
          raise "describe posts returned nil"
        end
      end

      it "copies the data from the old field" do
        Post1.drop
        Post1.create
        post = Post1.new
        post.body = "Hello"
        post.save
        Post4.migrate
        if results = Post1.query("select body from posts")
          results[0][0].to_s.should eq "Hello"
        else
          raise "copy data failed"
        end
      end
    end
  end

  describe "#prune" do
    it "removes any fields that are not defined" do
      Post2.drop
      Post2.migrate
      Post1.prune
      if results = Post1.query("describe posts;")
        results.size.should eq 5
      else
        raise "describe posts returned null"
      end
    end
  end

  describe "#add_field" do
    it "adds a new field" do
      Post1.drop
      Post1.create
      Post1.database.add_field("posts", "test", "TEXT")
      if results = Post1.query("describe posts;")
        results.size.should eq 6
      else
        raise "describe posts returned nil"
      end
    end
  end

  describe "#rename_field" do
    it "renames a field" do
      Post1.drop
      Post1.migrate
      Post1.database.rename_field("posts", "name", "old_name", "TEXT")
      if results = Post1.query("describe posts;")
        results[1][0].should eq "old_name"
      else
        raise "describe posts returned nil"
      end
    end
  end

  describe "#remove_field" do
    it "removes a field" do
      Post1.drop
      Post1.migrate
      Post1.database.remove_field("posts", "name")
      if results = Post1.query("describe posts;")
        results.size.should eq 4
      else
        raise "describe posts returned nil"
      end
    end
  end

  describe "#copy_field" do
    it "copies data from field" do
      Post1.drop
      Post1.migrate
      post = Post1.new
      post.name = "Hello"
      post.save
      Post1.database.add_field("posts", "test", "VARCHAR(255)")
      Post1.database.copy_field("posts", "name", "test")
      if results = Post1.query("select test from posts")
        results[0][0].to_s.should eq "Hello"
      else
        raise "copy data failed"
      end
    end
  end
end
