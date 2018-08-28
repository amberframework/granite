require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}

  def self.new_review(attributes = {} of Symbol | String => DB::Any)
    attrs = {
      name: "Basic Review",
      downvotes: 10,
      upvotes: 20_i64,
      published: true
    }.to_h.merge(attributes.to_h)
    Review.new(attrs)
  end

  def self.create_review(attributes = {} of Symbol | String => DB::Any)
    review = new_review(attributes.to_h)
    review.save!
    review
  end

  describe "{{ adapter.id }} Granite::Base" do

    describe "==" do
      it "correctly compares two identical reviews" do
        r1 = new_review
        r2 = new_review
        (r1 == r2).should be_truthy
      end

      it "correctly compares two identical records with different ids" do
        r1 = create_review
        r2 = create_review
        (r1 == r2).should_not be_truthy
      end

      it "correctly compares two almost identical records (1)" do
        r1 = new_review({name: "Test"})
        r2 = new_review({name: "Test 2"})
        (r1 == r2).should_not be_truthy
      end

      it "correctly compares two almose identical records (2)" do
        r1 = new_review({published: true})
        r2 = new_review({published: false})
        (r1 == r2).should_not be_truthy
      end

      it "correctly compares two record objects found by the same id" do
        base_review = create_review
        r1 = Review.find!(base_review.id)
        r2 = Review.find!(base_review.id)
        (r1 == r2).should be_truthy
      end
    end

    describe "sort" do

      it "sorts records by id if all other fields are the same" do
        Review.clear
        reviews = [] of Review
        100.times do
          review = create_review
          reviews << review
        end
        review_ids = reviews.map{|review| review.id.as(Int64)}.sort
        sorted = reviews.shuffle.sort.map(&.id)
        review_ids.should eq(sorted)
      end

      it "raises an exception if sorting with nil primary keys" do
        Review.clear
        reviews = [] of Review
        100.times do |num|
          review = new_review({downvotes: num})
          reviews << review
        end
        expect_raises(Exception) do
          sorted = reviews.shuffle.sort
        end
      end

    end

    describe "<=>" do
      it "compares records with primary keys" do
        r1 = create_review({downvotes: 50})
        r2 = create_review({downvotes: 10})
        (r1 <=> r2 < 0).should_not eq(0)
      end

      it "raises an exception if comparing a record without a primary key" do
        r1 = new_review
        r2 = create_review
        expect_raises(Exception) do
          r1 <=> r2
        end
      end

    end
  end
end
{% end %}
