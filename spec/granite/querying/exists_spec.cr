require "../../spec_helper"

describe ".exists?" do
  before_each do
    Parent.clear
  end

  describe "when there is a record with that ID" do
    describe "with a numeric PK" do
      it "should return true" do
        model = Parent.new(name: "Some Name")
        model.save.should be_true
        Parent.exists?(model.id).should be_true
      end
    end

    describe "with a string PK" do
      it "should return true" do
        Kvs.new(k: "EXISTS_ID").save.should be_true
        Kvs.exists?("EXISTS_ID").should be_true
      end
    end

    describe "with a namedtuple of args" do
      it "should return true" do
        model = Parent.new(name: "Some Name")
        model.save.should be_true
        Parent.exists?(name: "Some Name", id: model.id).should be_true
      end
    end

    describe "with a hash of args" do
      it "should return true" do
        model = Parent.new(name: "Some Name")
        model.save.should be_true
        Parent.exists?({:name => "Some Name", "id" => model.id}).should be_true
      end
    end

    describe "with a nil value" do
      it "should return true" do
        model = Student.new
        model.save.should be_true
        Student.exists?(name: nil, id: model.id).should be_true
      end
    end
  end

  describe "when there is not a record with that ID" do
    describe "with a numeric PK" do
      it "should return false" do
        Parent.exists?(234567).should be_false
      end
    end

    describe "with a string PK" do
      it "should return false" do
        Kvs.exists?("SOME_KEY").should be_false
      end
    end

    describe "with a namedtuple of args" do
      it "should return false" do
        model = Parent.new(name: "Some Name")
        model.save.should be_true
        Parent.exists?(name: "Some Other Name", id: model.id).should be_false
      end
    end

    describe "with a hash of args" do
      it "should return false" do
        model = Parent.new(name: "Some Name")
        model.save.should be_true
        Parent.exists?({:name => "Some Other Name", "id" => model.id}).should be_false
      end
    end

    describe "with a nil value" do
      it "should return false" do
        model = Student.new(name: "Jim")
        model.save.should be_true
        Student.exists?(name: nil, id: model.id).should be_false
      end
    end
  end
end
