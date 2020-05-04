require "./spec_helper"

class SomeClass
  def initialize(@model_class : Granite::Base.class); end

  def valid? : Bool
    @model_class.exists? 123
  end

  def table : String
    @model_class.table_name
  end
end

describe Granite::Base do
  it "class methods should work when type restricted to `Granite::Base`" do
    f = SomeClass.new(Teacher)
    f.valid?.should be_false
    f.table.should eq "teachers"
  end

  it "should allow false as a column value" do
    model = BoolModel.create active: false

    model.active.should be_false
    model.id.should eq 1

    fetched_model = BoolModel.find! model.id
    fetched_model.active.should be_false
  end

  describe "instantiation" do
    describe "with default values" do
      it "should instaniate correctly" do
        model = DefaultValues.new
        model.name.should eq "Jim"
        model.age.should eq 0.0
        model.is_alive.should be_true
      end
    end

    describe "with a named tuple" do
      it "should instaniate correctly" do
        model = DefaultValues.new name: "Fred", is_alive: false
        model.name.should eq "Fred"
        model.age.should eq 0.0
        model.is_alive.should be_false
      end
    end

    describe "with a hash" do
      it "should instaniate correctly" do
        model = DefaultValues.new({"name" => "Bob", "age" => 3.14})
        model.name.should eq "Bob"
        model.age.should eq 3.14
        model.is_alive.should be_true
      end
    end

    describe "with a UUID" do
      it "should instaniate correctly" do
        uuid = UUID.random
        model = UUIDNaturalModel.new uuid: uuid, field_uuid: uuid
        model.uuid.should be_a UUID?
        model.field_uuid.should be_a UUID?
        model.uuid.should eq uuid
        model.field_uuid.should eq uuid
      end
    end

    describe "with string numeric values" do
      it "should instaniate correctly" do
        model = StringConversion.new({"user_id" => "1", "int32" => "17", "float32" => "3.14", "float" => "92342.2342342"})

        model.user_id.should be_a Int64
        model.user_id.should eq 1

        model.int32.should be_a Int32
        model.int32.should eq 17

        model.float32.should be_a Float32
        model.float32.should eq 3.14_f32

        model.float.should be_a Float64
        model.float.should eq 92342.2342342
      end
    end
  end

  describe Log do
    it "should be logged as DEBUG" do
      backend = Log::MemoryBackend.new

      Log.builder.bind "granite", :debug, backend

      Person.first

      backend.entries.first.severity.debug?.should be_true
      backend.entries.first.message.should match /.*SELECT.*people.*id.*FROM.*people.*LIMIT.*1.*: .*\[\]/
    end

    it "should not be logged" do
      a = 0
      Log.for("granite.test").info { a = 1 }
      a.should eq 0
    end
  end

  describe "JSON" do
    describe ".from_json" do
      it "can create an object from json" do
        json_str = %({"name": "json::anyReview","upvotes": 2, "sentiment": 1.23, "interest": 4.56, "published": true})

        review = Review.from_json(json_str)
        review.name.should eq "json::anyReview"
        review.upvotes.should eq 2
        review.sentiment.should eq 1.23_f32
        review.interest.should eq 4.56
        review.published.should eq true
        review.created_at.should be_nil
      end

      it "can create an array of objects from json" do
        json_str = %([{"name": "json1","upvotes": 2, "sentiment": 1.23, "interest": 4.56, "published": true},{"name": "json2","upvotes": 0, "sentiment": 5.00, "interest": 6.99, "published": false}])

        review = Array(Review).from_json(json_str)
        review[0].name.should eq "json1"
        review[0].upvotes.should eq 2
        review[0].sentiment.should eq 1.23_f32
        review[0].interest.should eq 4.56
        review[0].published.should be_true
        review[0].created_at.should be_nil

        review[1].name.should eq "json2"
        review[1].upvotes.should eq 0
        review[1].sentiment.should eq 5.00_f32
        review[1].interest.should eq 6.99
        review[1].published.should be_false
        review[1].created_at.should be_nil
      end

      it "works with after_initialize" do
        model = AfterInit.from_json(%({"name": "after_initialize"}))

        model.name.should eq "after_initialize"
        model.priority.should eq 1000
      end

      describe "with default values" do
        it "correctly applies values" do
          model = DefaultValues.from_json(%({"name": "Bob"}))
          model.name.should eq "Bob"
          model.age.should eq 0.0
          model.is_alive.should be_true
        end
      end
    end

    describe "#to_json" do
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

    context "with json_options" do
      model = TodoJsonOptions.from_json(%({"task_name": "The Task", "priority": 9000}))
      it "should deserialize correctly" do
        model.name.should eq "The Task"
        model.priority.should be_nil
      end

      it "should serialize correctly" do
        model.to_json.should eq %({"task_name":"The Task"})
      end

      describe "when using timestamp fields" do
        TodoJsonOptions.import([
          TodoJsonOptions.new(name: "first todo", priority: 200),
          TodoJsonOptions.new(name: "second todo", priority: 500),
          TodoJsonOptions.new(name: "third todo", priority: 300),
        ])

        it "should serialize correctly" do
          todos = TodoJsonOptions.order(id: :asc).select
          todos[0].to_json.should eq %({"id":1,"task_name":"first todo","posted":"#{Time::Format::RFC_3339.format(todos[0].created_at!)}"})
          todos[1].to_json.should eq %({"id":2,"task_name":"second todo","posted":"#{Time::Format::RFC_3339.format(todos[1].created_at!)}"})
          todos[2].to_json.should eq %({"id":3,"task_name":"third todo","posted":"#{Time::Format::RFC_3339.format(todos[2].created_at!)}"})
        end
      end
    end
  end

  describe "YAML" do
    describe ".from_yaml" do
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

      describe "with default values" do
        it "correctly applies values" do
          model = DefaultValues.from_yaml(%(---\nname: Bob))
          model.name.should eq "Bob"
          model.age.should eq 0.0
          model.is_alive.should be_true
        end
      end
    end

    describe "#to_yaml" do
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

    context "with yaml_options" do
      model = TodoYamlOptions.from_yaml(%(---\ntask_name: The Task\npriority: 9000))
      it "should deserialize correctly" do
        model.name.should eq "The Task"
        model.priority.should be_nil
      end

      it "should serialize correctly" do
        model.to_yaml.should eq %(---\ntask_name: The Task\n)
      end

      describe "when using timestamp fields" do
        TodoYamlOptions.import([
          TodoYamlOptions.new(name: "first todo", priority: 200),
          TodoYamlOptions.new(name: "second todo", priority: 500),
          TodoYamlOptions.new(name: "third todo", priority: 300),
        ])

        it "should serialize correctly" do
          todos = TodoYamlOptions.order(id: :asc).select
          todos[0].to_yaml.should eq %(---\nid: 1\ntask_name: first todo\nposted: #{Time::Format::YAML_DATE.format(todos[0].created_at!)}\n)
          todos[1].to_yaml.should eq %(---\nid: 2\ntask_name: second todo\nposted: #{Time::Format::YAML_DATE.format(todos[1].created_at!)}\n)
          todos[2].to_yaml.should eq %(---\nid: 3\ntask_name: third todo\nposted: #{Time::Format::YAML_DATE.format(todos[2].created_at!)}\n)
        end
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

    it "works with enums" do
      model = EnumModel.new
      model.my_enum = MyEnum::One
      model.to_h.should eq({"id" => nil, "my_enum" => MyEnum::One})
    end
  end

  # Only PG supports array types
  {% if env("CURRENT_ADAPTER") == "pg" %}
    describe "Array(T)" do
      describe "with values" do
        it "should instantiate correctly" do
          model = ArrayModel.new str_array: ["foo", "bar"]
          model.str_array.should eq ["foo", "bar"]
        end

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
          model.f64_array.should be_a(Array(Float64))
          model.f64_array.should eq [] of Float64
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
          model.f64_array.should be_a(Array(Float64))
          model.f64_array.should eq [] of Float64
          model.bool_array.should be_nil
        end
      end
    end
  {% end %}
end
