require "../../spec_helper"

describe "#query_builder_methods" do
  describe "#where" do
    describe "with array argument" do
      it "correctly queries string fields" do
        review1 = Review.create(name: "one")
        review2 = Review.create(name: "two")

        found = Review.where(name: ["one", "two"]).select
        found[0].id.should eq review2.id
        found[1].id.should eq review1.id
      end

      it "correctly queries number fields" do
        Review.clear
        review1 = Review.create(name: "one", downvotes: 99)
        review2 = Review.create(name: "two", downvotes: -4)

        found = Review.where(downvotes: [99, -4]).select
        found[0].id.should eq review2.id
        found[1].id.should eq review1.id
      end

      # Sqlite doesnt have bool literals
      {% if env("CURRENT_ADAPTER") == "sqlite" %}
        it "correctly queries bool fields" do
          Review.clear
          Review.create(name: "one", published: 1)
          review2 = Review.create(name: "two", published: 0)

          found = Review.where(published: [0]).select

          found.size.should eq 1
          found[0].id.should eq review2.id
        end
      {% else %}
        it "correctly queries bool fields" do
          Review.clear
          Review.create(name: "one", published: true)
          review2 = Review.create(name: "two", published: false)

          found = Review.where(published: [false]).select
          found.size.should eq 1
          found[0].id.should eq review2.id
        end
      {% end %}
    end
  end
end
