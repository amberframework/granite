require "./spec_helper"

describe SqliteAdapter do
  Spec.before_each do
    Comment.clear
  end

  describe "#all" do
    pending "should find all the comments" do
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
    pending "should find the comment by id" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      id = comment.id
      comment = Comment.find id
      comment.id.should eq 1
    end
  end

  describe "#save" do
    pending "should create a new comment" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.body = "Test Comment"
      comment.save
      comment.id.should eq 1
    end

    pending "should update an existing comment" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      comment.name = "Test Comment 2"
      comment.save
      comment = Comment.find 1
      if comment
        comment.name.should eq "Test Comment 2"
      end
    end
  end

  describe "#destroy" do
    pending "should destroy a comment" do
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

