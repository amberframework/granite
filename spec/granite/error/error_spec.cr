require "../../spec_helper"

describe Granite::Error do
  it "should convert to json" do
    Granite::Error.new("field", "error message").to_json.should eq %({"field":"field","message":"error message"})
  end
end
