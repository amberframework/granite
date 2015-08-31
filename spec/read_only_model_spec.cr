require "./spec_helper"

describe ReadOnlyModel do
  Spec.before_each do
    Post.clear
  end

  describe "#all" do
    it "should find all the months and counts for posts" do
      post = Post.new
      post.name = "Test Post"
      post.save
      post = Post.new
      post.name = "Test Post 2"
      post.save
      posts_by_month = PostsByMonth.all("GROUP BY MONTH(created_at)")
      posts_by_month.total.should eq 2
    end
  end
end

