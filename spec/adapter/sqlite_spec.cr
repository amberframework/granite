# TODO: SQLite is failing in a Docker Container.  Disabling for now

require "./spec_helper"
require "../src/adapter/sqlite"

class Comment < Kemalyst::Model
  adapter sqlite 
  sql_mapping({ 
    name: ["TEXT", String],
    body: ["TEXT", String]
  })
end

Comment.drop
Comment.create

describe Kemalyst::Adapter::Sqlite do
  Spec.before_each do
    Comment.clear
  end

  describe "#all" do
    it "finds all the comments" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      comment = Comment.new
      comment.name = "Test Comment 2"
      comment.save
      comments = Comment.all
      comments.size.should eq 2
    end
  end

  describe "#find" do
    it "finds the comment by id" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      comment = Comment.find comment.id
      comment.should_not be_nil
    end
  end

  describe "#save" do
    it "creates a new comment" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.body = "Test Comment"
      comment.save
      comment.id.should eq 1
    end

    it "updates an existing comment" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      comment.name = "Test Comment 2"
      comment.save
      comments = Comment.all
      comments.size.should eq 1
      comment = Comment.find comments[0].id
      if comment
        comment.name.should eq "Test Comment 2"
      else
       raise "Comment should exist" 
      end
    end
  end

  describe "#destroy" do
    it "destroys a comment" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      id = comment.id
      comment.destroy
      comment = Comment.find id
      comment.should be_nil
    end
  end
end

