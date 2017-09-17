require "./spec_helper"
require "../src/adapter/sqlite"

class CommentThread < Granite::ORM::Base
  adapter sqlite
  table_name comment_threads

  has_many :comments
  has_many :stars, through: :comments

  field name : String
end

class Comment < Granite::ORM::Base
  adapter sqlite
  table_name comments

  belongs_to :comment_thread
  belongs_to :star

  field name : String
  field body : String
end

class Star < Granite::ORM::Base
  adapter sqlite

  has_many :comments
  has_many :comment_threads, through: :comments

  field name : String
end

class Reaction < Granite::ORM::Base
  adapter sqlite
  table_name reactions
  primary custom_id : Int64
  field emote : String
end

CommentThread.exec("DROP TABLE IF EXISTS comment_threads;")
CommentThread.exec("CREATE TABLE comment_threads (
  id INTEGER NOT NULL PRIMARY KEY,
  name VARCHAR
);
")

Comment.exec("DROP TABLE IF EXISTS comments;")
Comment.exec("CREATE TABLE comments (
  id INTEGER NOT NULL PRIMARY KEY,
  name VARCHAR,
  body VARCHAR,
  comment_thread_id INTEGER,
  star_id INTEGER
);
")

Star.exec("DROP TABLE IF EXISTS stars;")
Star.exec("CREATE TABLE stars (
  id INTEGER NOT NULL PRIMARY KEY,
  name VARCHAR
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
    CommentThread.clear
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

  describe "#first" do
    it "finds the first comment" do
      comment1 = Comment.new
      comment1.name = "Test Comment"
      comment1.save
      comment2 = Comment.new
      comment2.name = "Test Comment 2"
      comment2.save
      comment = Comment.first
      comment.not_nil!.id.should eq comment1.id
    end

    it "supports a SQL clause" do
      comment1 = Comment.new
      comment1.name = "Test Comment"
      comment1.save
      comment2 = Comment.new
      comment2.name = "Test Comment 2"
      comment2.save
      comment = Comment.first("ORDER BY comments.name DESC")
      comment.not_nil!.id.should eq comment2.id
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

  describe "#belongs_to" do
    it "provides a method to retrieve parent" do
      comment_thread = CommentThread.new
      comment_thread.name = "Test Thread"
      comment_thread.save

      comment = Comment.new
      comment.name = "Test Comment"
      comment.comment_thread_id = comment_thread.id
      comment.save

      comment.comment_thread.name.should eq "Test Thread"
    end

    it "provides a method to set parent" do
      comment_thread = CommentThread.new
      comment_thread.name = "Test Thread"
      comment_thread.save

      comment = Comment.new
      comment.name = "Test Comment"
      comment.comment_thread = comment_thread
      comment.save

      comment.comment_thread_id.should eq comment_thread.id
    end
  end

  describe "#has_many" do
    it "provides a method to retrieve children" do
      comment_thread = CommentThread.new
      comment_thread.name = "Test Thread"
      comment_thread.save

      comment = Comment.new
      comment.name = "Test Comment 1"
      comment.comment_thread = comment_thread
      comment.save
      comment = Comment.new
      comment.name = "Test Comment 2"
      comment.comment_thread = comment_thread
      comment.save
      comment = Comment.new
      comment.name = "Test Comment 3"
      comment.save

      comment_thread.comments.size.should eq 2
    end
  end

  describe "#has_many, through:" do
    it "provides a method to retrieve children through another table" do
      comment_thread = CommentThread.new
      comment_thread.name = "Test Thread"
      comment_thread.save

      star = Star.new
      star.name = "Test Star"
      star.save

      comment = Comment.new
      comment.name = "Test Comment 1"
      comment.comment_thread = comment_thread
      comment.star = star
      comment.save
      comment = Comment.new
      comment.name = "Test Comment 2"
      comment.comment_thread = comment_thread
      comment.star = star
      comment.save
      comment = Comment.new
      comment.name = "Test Comment 3"
      comment.save

      comment_thread.stars.size.should eq 2
      star.comment_threads.size.should eq 2
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
