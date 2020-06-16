require "../../spec_helper"

describe Granite::Query::BuilderMethods do
  describe "#where" do
    describe "with array arguments" do
      it "correctly queries all rows with a list of id values" do
        review1 = Review.create(name: "one")
        review2 = Review.create(name: "two")

        found = Review.where(id: [review1.id, review2.id]).select
        found[0].id.should eq review2.id
        found[1].id.should eq review1.id
      end

      it "correctly queries all rows with a list of id values and names" do
        review1 = Review.create(name: "one")
        review2 = Review.create(name: "two")

        found = Review.where(name: ["one", "two"]).and(id: [review1.id, review2.id]).select
        found[0].id.should eq review2.id
        found[1].id.should eq review1.id
      end

      it "correctly queries all rows with a list of id values or names" do
        review1 = Review.create(name: "one")
        review2 = Review.create(name: "two")

        found = Review.where(id: [1001, 1002]).or(name: ["one", "two"]).select
        found[0].id.should eq review2.id
        found[1].id.should eq review1.id

        found = Review.where(name: ["one", "two"]).or(id: [1001, 1002]).select
        found[0].id.should eq review2.id
        found[1].id.should eq review1.id
      end

      it "correctly queries with ids fields which doest exists" do
        Review.create(name: "one")
        Review.create(name: "two")

        found = Review.where(id: [1001, 1002]).select
        found.size.should eq 0
      end
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

  describe "#exists?" do
    describe "when there is a record with that ID" do
      describe "when querying on the PK" do
        it "should return true" do
          model = Parent.new(name: "Some Name")
          model.save.should be_true
          Parent.where(id: model.id).exists?.should be_true
        end
      end

      describe "with multiple args" do
        it "should return true" do
          model = Parent.new(name: "Some Name")
          model.save.should be_true
          Parent.where(name: "Some Name", id: model.id).exists?.should be_true
        end
      end
    end

    describe "when there is not a record with that ID" do
      describe "when querying on the PK" do
        it "should return false" do
          Parent.where(id: 234567).exists?.should be_false
        end
      end

      describe "with multiple args" do
        it "should return false" do
          model = Parent.new(name: "Some Name")
          model.save.should be_true
          Parent.where(name: "Some Other Name", id: model.id).exists?.should be_false
        end
      end
    end
  end
end
