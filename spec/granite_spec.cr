require "./spec_helper"
require "logger"

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
  end

  describe JSON do
    it "should not include internal ivars" do
      DefaultValues.new.to_json.should eq %({"name":"Jim","is_alive":true,"age":0.0})
    end
  end

  describe YAML do
    it "should not include internal ivars" do
      DefaultValues.new.to_yaml.should eq %(---\nname: Jim\nis_alive: true\nage: 0.0\n)
    end
  end

  describe Logger do
    describe "when logger is set to IO" do
      it "should be logged as DEBUG" do
        IO.pipe do |r, w|
          Granite.settings.logger = Logger.new(w, Logger::Severity::DEBUG)

          Person.first

          r.gets.should match /D, \[.*\] DEBUG -- : .*SELECT.*people.*id.*FROM.*people.*LIMIT.*1.*: .*\[\]/
        end
      end
    end

    describe "when logger is set to nil" do
      it "should not be logged" do
        Granite.settings.logger = Logger.new nil

        a = 0
        Granite.settings.logger.info { a = 1 }
        a.should eq 0
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
