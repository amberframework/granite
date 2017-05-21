require "./spec_helper"
require "../src/adapter/sqlite"

class Comment < Granite::ORM
  adapter sqlite
  table_name comments
  field name : String
  field body : String
end

class Reaction < Granite::ORM
  adapter sqlite
  table_name reactions
  primary custom_id : Int64
  field emote : String
end

Comment.exec("DROP TABLE IF EXISTS comments;")
Comment.exec("CREATE TABLE comments (
  id INTEGER NOT NULL PRIMARY KEY,
  name VARCHAR,
  body VARCHAR
);
")

Reaction.exec("DROP TABLE IF EXISTS reactions;")
Reaction.exec("CREATE TABLE reactions (
  custom_id INTEGER NOT NULL PRIMARY KEY,
  emote VARCHAR
);
")

describe Granite::Adapter::Sqlite do
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

  describe "#find_by" do
    it "finds the comment by field" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      name = comment.name
      comment = Comment.find_by("name", name)
      comment.should_not be_nil
    end

    it "finds the comment by field using a symbol" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      name = comment.name
      comment = Comment.find_by(:name, name)
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

  describe "Reaction model with custom primary key" do
    Spec.before_each do
      Reaction.clear
    end

    describe "#find" do
      it "finds the reaction by custom_id" do
        reaction = Reaction.new
        reaction.emote = ":test:"
        reaction.save
        pk = reaction.custom_id
        reaction = Reaction.find pk
        reaction.should_not be_nil
      end
    end

    describe "#save" do
      it "updates an existing reaction" do
        reaction = Reaction.new
        reaction.emote = ":test:"
        reaction.save
        reaction.emote = ":test2:"
        reaction.save
        reaction = Reaction.find 1
        if reaction
          reaction.emote.should eq ":test2:"
        end
      end
    end

    describe "#destroy" do
      it "destroys a reaction" do
        reaction = Reaction.new
        reaction.emote = ":test:"
        reaction.save
        pk = reaction.custom_id
        reaction.destroy
        reaction = Reaction.find pk
        reaction.should be_nil
      end
    end
  end
end
