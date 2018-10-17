require "../../spec_helper"

describe "UUID creation" do
  it "correctly sets a RFC4122 V4 UUID on save" do
    item = UUIDModel.new
    item.uuid.should be_nil
    item.save
    item.uuid.should be_a(String)
    uuid = UUID.new item.uuid!
    uuid.version.to_s.should eq "V4"
    uuid.variant.to_s.should eq "RFC4122"
  end
end
