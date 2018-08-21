require "../../spec_helper"

describe "#destroy" do
  it "destroys an object" do
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save

    id = parent.id
    parent.destroy
    found = Parent.find id
    found.should be_nil
  end

  it "updates states of destroyed and persisted" do
    parent = Parent.new
    parent.destroyed?.should be_false
    parent.persisted?.should be_false

    parent.name = "Test Parent"
    parent.save
    parent.destroyed?.should be_false
    parent.persisted?.should be_true

    parent.destroy
    parent.destroyed?.should be_true
    parent.persisted?.should be_false
  end

  describe "with a custom primary key" do
    it "destroys an object" do
      school = School.new
      school.name = "Test School"
      school.save
      primary_key = school.custom_id
      school.destroy

      found_school = School.find primary_key
      found_school.should be_nil
    end
  end

  describe "with a modulized model" do
    it "destroys an object" do
      county = Nation::County.new
      county.name = "Test County"
      county.save
      primary_key = county.id
      county.destroy

      found_county = Nation::County.find primary_key
      found_county.should be_nil
    end
  end
end

describe "#destroy!" do
  it "destroys an object" do
    parent = Parent.new
    parent.name = "Test Parent"
    parent.save!

    id = parent.id
    parent.destroy
    found = Parent.find id
    found.should be_nil
  end

  it "does not destroy but raise an exception" do
    callback_with_abort = CallbackWithAbort.new
    callback_with_abort.name = "DestroyRaisesException"
    callback_with_abort.abort_at = "temp"
    callback_with_abort.do_abort = false
    callback_with_abort.save!
    callback_with_abort.abort_at = "before_destroy"
    callback_with_abort.do_abort = true

    expect_raises(Granite::RecordNotDestroyed, "CallbackWithAbort") do
      callback_with_abort.destroy!
    end

    CallbackWithAbort.find_by(name: callback_with_abort.name).should_not be_nil
  end
end
