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

      it "sorts records by other fields if the ids are the same" do
        Review.clear
        reviews = [] of Review
        100.times do |num|
          review = new_review({downvotes: num})
          reviews << review
        end
        review_downvotes = reviews.map{|review| review.downvotes.as(Int32)}.sort
        sorted = reviews.shuffle.sort.map(&.downvotes)
        review_downvotes.should eq(sorted)
      end

    end

    describe "<=>" do
      it "compares records by id before other attributes" do
        r1 = create_review({downvotes: 50})
        r2 = create_review({downvotes: 10})
        (r1 <=> r2 < 0).should be_truthy
      end

      it "compares other fields if the ids are the same" do
        r1 = new_review({downvotes: 50})
        r2 = new_review({downvotes: 10})
        (r1 <=> r2 > 0).should be_truthy
      end

      it "compares Bool fields" do
        r1 = create_review({published: true})
        r2 = create_review({published: false})
        (r1 <=> r2).should_not eq(0)
      end

      it "compares belongs_to field ids" do
        teacher_1 = Teacher.create(name: "Test Teacher")
        teacher_2 = Teacher.create(name: "Test Teacher")
        klass_1 = Klass.new(name: "Test Class")
        klass_1.teacher = teacher_1
        klass_2 = Klass.new(name: "Test Class")
        klass_2.teacher = teacher_2
        (klass_1 <=> klass_2).should_not eq(0)
      end
    end
  end
end
{% end %}
