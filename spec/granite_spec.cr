require "./spec_helper"

describe "Granite::Base" do
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
        model = AfterInit.from_json(%({"name": "after_initialize"}))

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
        collection.should eq %([{"name":"todo 1","priority":1},{"name":"todo 2","priority":2},{"name":"todo 3","priority":3}])
      end
    end
  end

  describe "YAML" do
    context ".from_yaml" do
      it "can create an object from YAML" do
        yaml_str = %(---\nname: yaml::anyReview\nupvotes: 2\nsentiment: 1.23\ninterest: 4.56\npublished: true)

        review = Review.from_yaml(yaml_str)
        review.name.should eq "yaml::anyReview"
        review.upvotes.should eq 2
        review.sentiment.should eq 1.23.to_f32
        review.interest.should eq 4.56
        review.published.should eq true
        review.created_at.should be_nil
      end

      it "can create an array of objects from YAML" do
        yaml_str = "---\n- name: yaml1\n  upvotes: 2\n  sentiment: 1.23\n  interest: 4.56\n  published: true\n- name: yaml2\n  upvotes: 0\n  sentiment: !!float 5\n  interest: 6.99\n  published: false"

        review = Array(Review).from_yaml(yaml_str)
        review[0].name.should eq "yaml1"
        review[0].upvotes.should eq 2
        review[0].sentiment.should eq 1.23.to_f32
        review[0].interest.should eq 4.56
        review[0].published.should be_true
        review[0].created_at.should be_nil

        review[1].name.should eq "yaml2"
        review[1].upvotes.should eq 0
        review[1].sentiment.should eq 5.00.to_f32
        review[1].interest.should eq 6.99
        review[1].published.should be_false
        review[1].created_at.should be_nil
      end

      it "works with after_initialize" do
        model = AfterInit.from_yaml(%(---\nname: after_initialize))

        model.name.should eq "after_initialize"
        model.priority.should eq 1000
      end
    end

    context ".to_yaml" do
      it "emits nil values when told" do
        t = TodoEmitNull.new(name: "test todo", priority: 20)
        result = %(---\nid: \nname: test todo\npriority: 20\ncreated_at: \nupdated_at: \n)

        t.to_yaml.should eq result
      end

      it "does not emit nil values by default" do
        t = Todo.new(name: "test todo", priority: 20)
        result = %(---\nname: test todo\npriority: 20\n)

        t.to_yaml.should eq result
      end

      it "works with array of models" do
        todos = [
          Todo.new(name: "todo 1", priority: 1),
          Todo.new(name: "todo 2", priority: 2),
          Todo.new(name: "todo 3", priority: 3),
        ]

        collection = todos.to_yaml
        collection.should eq %(---\n- name: todo 1\n  priority: 1\n- name: todo 2\n  priority: 2\n- name: todo 3\n  priority: 3\n)
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

  # Only PG supports array types
  {% if env("CURRENT_ENV") == "pg" %}
    describe "Array(T)" do
      describe "with values" do
        it "should save correctly" do
          model = ArrayModel.new
          model.id = 1
          model.str_array = ["jack", "john", "jill"]
          model.i16_array = [10_000_i16, 20_000_i16, 30_000_i16]
          model.i32_array = [1_000_000_i32, 2_000_000_i32, 3_000_000_i32, 4_000_000_i32]
          model.i64_array = [100_000_000_000_i64, 200_000_000_000_i64, 300_000_000_000_i64, 400_000_000_000_i64]
          model.f32_array = [1.123_456_78_f32, 1.234_567_899_998_741_4_f32]
          model.f64_array = [1.123_456_789_011_23_f64, 1.234_567_899_998_741_4_f64]
          model.bool_array = [true, true, false, true, false, false]
          model.save.should be_true
        end

        it "should read correctly" do
          model = ArrayModel.find! 1
          model.str_array!.should be_a Array(String)
          model.str_array!.should eq ["jack", "john", "jill"]
          model.i16_array!.should be_a Array(Int16)
          model.i16_array!.should eq [10_000_i16, 20_000_i16, 30_000_i16]
          model.i32_array!.should be_a Array(Int32)
          model.i32_array!.should eq [1_000_000_i32, 2_000_000_i32, 3_000_000_i32, 4_000_000_i32]
          model.i64_array!.should be_a Array(Int64)
          model.i64_array!.should eq [100_000_000_000_i64, 200_000_000_000_i64, 300_000_000_000_i64, 400_000_000_000_i64]
          model.f32_array!.should be_a Array(Float32)
          model.f32_array!.should eq [1.123_456_78_f32, 1.234_567_899_998_741_4_f32]
          model.f64_array!.should be_a Array(Float64)
          model.f64_array!.should eq [1.123_456_789_011_23_f64, 1.234_567_899_998_741_4_f64]
          model.bool_array!.should be_a Array(Bool)
          model.bool_array!.should eq [true, true, false, true, false, false]
        end
      end

      describe "with empty array" do
        it "should save correctly" do
          model = ArrayModel.new
          model.id = 2
          model.str_array = [] of String
          model.save.should be_true
        end

        it "should read correctly" do
          model = ArrayModel.find! 2
          model.str_array.should be_a Array(String)?
          model.str_array!.should eq [] of String
          model.i16_array.should be_nil
          model.i32_array.should be_nil
          model.i64_array.should be_nil
          model.f32_array.should be_nil
          model.f64_array.should be_nil
          model.bool_array.should be_nil
        end
      end
    end
  {% end %}
end
