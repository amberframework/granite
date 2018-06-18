require "../../spec_helper"

class RecordInvalidParent; end
class Granite::RecordInvalidParent; end

describe Granite::RecordInvalid do
  context "when used with an class" do
    it "should have an message" do
      Granite::RecordInvalid
        .new(RecordInvalidParent.name)
        .message
        .should eq("Could not process RecordInvalidParent")
    end
  end

  context "when used with an module" do
    it "should have an message" do
      Granite::RecordInvalid
        .new(Granite::RecordInvalidParent.name)
        .message
        .should eq("Could not process Granite::RecordInvalidParent")
    end
  end
end
