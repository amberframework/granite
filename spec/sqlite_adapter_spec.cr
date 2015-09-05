require "./spec_helper"

describe SqliteAdapter do
  Spec.before_each do
    Comment.clear
  end

  describe "#all" do
    it "should find all the comments" do
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
    it "should find the comment by id" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.save
      comment = Comment.find comment.id
      comment.should_not be_nil
    end
  end

  describe "#save" do
    it "should create a new comment" do
      comment = Comment.new
      comment.name = "Test Comment"
      comment.body = "Test Comment"
      comment.save
      comment.id.should eq 1
    end

    it "should update an existing comment" do
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
    it "should destroy a comment" do
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

