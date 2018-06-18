require "../../spec_helper"

class RecordNotDestroyedParent; end
class Granite::RecordNotDestroyedParent; end

describe Granite::RecordNotDestroyed do
  context "when used with an class" do
    it "should have an message" do
      Granite::RecordNotDestroyed
        .new(RecordNotDestroyedParent.name)
        .message
        .should eq("Could not destroy RecordNotDestroyedParent")
    end
  end

  context "when used with an module" do
    it "should have an message" do
      Granite::RecordNotDestroyed
        .new(Granite::RecordNotDestroyedParent.name)
        .message
        .should eq("Could not destroy Granite::RecordNotDestroyedParent")
    end
  end
end
