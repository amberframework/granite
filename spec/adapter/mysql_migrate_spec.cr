require "./spec_helper"
require "../src/adapter/mysql"

class Post1 < Kemalyst::Model
  adapter mysql
  sql_mapping({
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(255)", String],
  }, posts)
end

# Add a new field
class Post2 < Kemalyst::Model
  adapter mysql
  sql_mapping({
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(255)", String],
    flag: ["BOOLEAN", Bool],
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
      cnt = 0
      Post2.query("describe posts;") do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 6
    end

    context "type change" do
      it "renames the field to old_*" do
        Post1.drop
        Post1.create
        Post3.migrate
        field = ""
        Post1.query("describe posts;") do |results|
          cnt = 0
          results.each do
            field = results.read(String) if cnt == 3
            cnt += 1
          end
        end
        field.should eq "old_body"
      end

      it "adds a new field" do
        Post1.drop
        Post1.create
        Post3.migrate
        cnt = 0
        Post2.query("describe posts;") do |results|
          results.each { cnt += 1 }
        end
        cnt.should eq 6
      end

      it "copies the data from the old field" do
        Post1.drop
        Post1.create
        post = Post1.new
        post.body = "Hello"
        post.save
        Post3.migrate
        field = ""
        Post1.query("select body from posts") do |results|
          results.each do
            field = results.read(String)
          end
        end
        field.should eq "Hello"
      end
    end

    context "size change" do
      it "renames the field to old_*" do
        Post1.drop
        Post1.create
        Post4.migrate
        field = ""
        Post1.query("describe posts;") do |results|
          cnt = 0
          results.each do
            field = results.read(String) if cnt == 3
            cnt += 1
          end
        end
        field.should eq "old_body"
      end

      it "adds a new field" do
        Post1.drop
        Post1.create
        Post4.migrate
        cnt = 0
        Post2.query("describe posts;") do |results|
          results.each { cnt += 1 }
        end
        cnt.should eq 6
      end

      it "copies the data from the old field" do
        Post1.drop
        Post1.create
        post = Post1.new
        post.body = "Hello"
        post.save
        Post4.migrate
        field = ""
        Post1.query("select body from posts") do |results|
          results.each do
            field = results.read(String)
          end
        end
        field.should eq "Hello"
      end
    end
  end

  describe "#prune" do
    it "removes any fields that are not defined" do
      Post2.drop
      Post2.migrate
      Post1.prune
      cnt = 0
      Post2.query("describe posts;") do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 5
    end
  end

  describe "#add_field" do
    it "adds a new field" do
      Post1.drop
      Post1.create
      Post1.exec(Post1.adapter.add_field("posts", "test", "TEXT"))
      cnt = 0
      Post2.query("describe posts;") do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 6
    end
  end

  describe "#rename_field" do
    it "renames a field" do
      Post1.drop
      Post1.create
      Post1.exec(Post1.adapter.rename_field("posts", "name", "old_name", "TEXT"))
      field = ""
      Post1.query("describe posts;") do |results|
        cnt = 0
        results.each do
          field = results.read(String) if cnt == 1
          cnt += 1
        end
      end
      field.should eq "old_name"
    end
  end

  describe "#remove_field" do
    it "removes a field" do
      Post1.drop
      Post1.create
      Post1.exec(Post1.adapter.remove_field("posts", "name"))
      cnt = 0
      Post2.query("describe posts;") do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 4
    end
  end

  describe "#copy_field" do
    it "copies data from field" do
      Post1.drop
      Post1.create
      post = Post1.new
      post.name = "Hello"
      post.save
      Post1.exec(Post1.adapter.add_field("posts", "test", "VARCHAR(255)"))
      Post1.exec(Post1.adapter.copy_field("posts", "name", "test"))
      field = ""
      Post1.query("select test from posts") do |results|
        results.each do
          field = results.read(String)
        end
      end
      field.should eq "Hello"
    end
  end
end
