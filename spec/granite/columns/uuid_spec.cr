require "../../spec_helper"

describe "UUID creation" do
  it "correctly sets a RFC4122 V4 UUID on save" do
    item = UUIDModel.new
    item.uuid?.should be_nil
    item.save
    item.uuid.should be_a(UUID)
    item.uuid.try(&.version.v4?).should be_true
    item.uuid.try(&.variant.rfc4122?).should be_true
  end
end
