require "../../spec_helper"

describe "#touch" do
  it "should raise on new record" do
    expect_raises Exception, "Cannot touch on a new record object" { TimeTest.new.touch }
  end

  it "should raise on non existent field" do
    expect_raises Exception, "Column 'foo' does not exist on type 'TimeTest'." do
      model = TimeTest.create(name: "foo")
      model.touch(:foo)
    end
  end

  it "should raise on non `Time` field" do
    expect_raises Exception, "TimeTest.name cannot be touched.  It is not of type `Time`." do
      model = TimeTest.create(name: "foo")
      model.touch(:name)
    end
  end

  it "updates updated_at on an object" do
    old_time = Time.utc.at_beginning_of_second
    object = TimeTest.create(test: old_time)

    sleep 3

    new_time = Time.utc.at_beginning_of_second
    object.touch

    object.updated_at.should eq new_time
    object.test.should eq old_time
    object.created_at.should eq old_time
  end

  it "updates updated_at + custom fields on an object" do
    old_time = Time.utc.at_beginning_of_second
    object = TimeTest.create(test: old_time)

    sleep 3

    new_time = Time.utc.at_beginning_of_second
    object.touch("test")

    object.updated_at.should eq new_time
    object.test.should eq new_time
    object.created_at.should eq old_time
  end
end
