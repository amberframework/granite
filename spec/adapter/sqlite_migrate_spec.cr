require "./spec_helper"
require "../src/adapter/sqlite"

class Comment < Kemalyst::Model
  adapter sqlite 
  sql_mapping({ 
    name: ["TEXT", String],
    body: ["TEXT", String]
  })
end

class Comment2 < Kemalyst::Model
  adapter sqlite
  sql_mapping({ 
    name: ["TEXT", String],
    body: ["TEXT", String],
    flag: ["BOOLEAN", Bool]
  }, comments)
end

Comment.drop
Comment.create

describe Kemalyst::Adapter::Sqlite do
  Spec.before_each do
    Comment.clear
  end

  describe "#migrate" do
    it "raises an exception" do
      begin
        Comment2.migrate
      rescue ex
        ex.message.should eq "Not Available for Sqlite"
      end
    end
  end

  describe "#prune" do
    it "raises an exception" do
      begin
        Comment.prune
      rescue ex
        ex.message.should eq "Not Available for Sqlite"
      end
    end
  end

  describe "#add_field" do
    it "raises an exception" do
      begin
        Comment.database.add_field("users", "test", "TEXT")
      rescue ex
        ex.message.should eq "Not Available for Sqlite"
      end
    end

  end

  describe "#rename_field" do
    it "raises an exception" do
      begin
        Comment.database.rename_field("users", "name", "old_name", "TEXT")
      rescue ex
        ex.message.should eq "Not Available for Sqlite"
      end
    end
  end

  describe "#remove_field" do
    it "raises an exception" do
      begin
        Comment.database.remove_field("users", "name")
      rescue ex
        ex.message.should eq "Not Available for Sqlite"
      end
    end
  end

  describe "#copy_field" do
    it "copies data from field" do
      Comment.drop
      Comment.create
      comment = Comment.new
      comment.name = "Hello"
      comment.save
      Comment.database.copy_field("comments", "name", "body")
      if results = Comment.query("select body from comments")
        results[0][0].to_s.should eq "Hello"
      else
        raise "copy data failed"
      end
    end
  end
  
end

