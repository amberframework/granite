require "./spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  module {{adapter.capitalize.id}}
    describe "{{ adapter.id }} Granite::Base" do
      describe "JSON" do
        context ".from_json" do
          it "can create an object from json" do
            json_str = %({"name": "json::anyReview","upvotes": 2, "sentiment": 1.23, "interest": 4.56, "published": true})

            review = Review.from_json(json_str)
            review.name.should eq "json::anyReview"
            review.upvotes.should eq 2
            review.sentiment.should eq 1.23.to_f32
            review.interest.should eq 4.56
            review.published.should eq true
            review.created_at.should be_nil
          end

          it "can create an array of objects from json" do
            json_str = %([{"name": "json1","upvotes": 2, "sentiment": 1.23, "interest": 4.56, "published": true},{"name": "json2","upvotes": 0, "sentiment": 5.00, "interest": 6.99, "published": false}])

            review = Array(Review).from_json(json_str)
            review[0].name.should eq "json1"
            review[0].upvotes.should eq 2
            review[0].sentiment.should eq 1.23.to_f32
            review[0].interest.should eq 4.56
            review[0].published.should be_true
            review[0].created_at.should be_nil

            review[1].name.should eq "json2"
            review[1].upvotes.should eq 0
            review[1].sentiment.should eq 5.00.to_f32
            review[1].interest.should eq 6.99
            review[1].published.should be_false
            review[1].created_at.should be_nil
          end

          it "works with after_initialize" do
            model = AfterJSONInit.from_json(%({"name": "after_initialize"}))

            model.name.should eq "after_initialize"
            model.priority.should eq 1000
          end
        end

        context ".to_json" do
          it "emits nil values when told" do
            t = TodoEmitNull.new(name: "test todo", priority: 20)
            result = %({"id":null,"name":"test todo","priority":20,"created_at":null,"updated_at":null})

            t.to_json.should eq result
          end

          it "does not emit nil values by default" do
            t = Todo.new(name: "test todo", priority: 20)
            result = %({"name":"test todo","priority":20})

            t.to_json.should eq result
          end

          it "works with array of models" do
            todos = [
              Todo.new(name: "todo 1", priority: 1),
              Todo.new(name: "todo 2", priority: 2),
              Todo.new(name: "todo 3", priority: 3),
            ]

            collection = todos.to_json
            collection.should eq(%([{"name":"todo 1","priority":1},{"name":"todo 2","priority":2},{"name":"todo 3","priority":3}]))
          end
        end
      end

      describe "#to_h" do
        it "convert object to hash" do
          t = Todo.new(name: "test todo", priority: 20)
          result = {"id" => nil, "name" => "test todo", "priority" => 20, "created_at" => nil, "updated_at" => nil}

          t.to_h.should eq result
        end

        it "honors custom primary key" do
          s = Item.new(item_name: "Hacker News")
          s.item_id = "three"
          s.to_h.should eq({"item_name" => "Hacker News", "item_id" => "three"})
        end
      end
    end
  end
{% end %}
