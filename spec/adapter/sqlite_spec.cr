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
