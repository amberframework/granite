require "../../spec_helper"

describe "has_one" do
  it "provides a setter to set childrens's foriegn_key from parent" do
    profile = Profile.new
    profile.name = "Test Profile"
    profile.save

    user = User.new
    user.email = "test@domain.com"
    user.save

    user.profile = profile
    profile.user_id.should eq profile.id
  end

  it "provides a method to retrieve associated objects" do
    profile = Profile.new
    profile.name = "Test Profile"
    profile.save

    user = User.new
    user.email = "test@domain.com"
    user.save

    # profile's foriegn_key is now set, so calling save again
    user.profile = profile
    profile.save

    retrieved_profile = user.profile!
    retrieved_profile.id.should eq profile.id
  end

  it "provides a method to retrieve associated object that will raise if record is not found" do
    user = User.new
    user.email = "test@domain.com"
    user.save

    expect_raises Granite::Querying::NotFound, "No Profile found where user_id = 3" { user.profile! }
  end

  it "provides the ability to use a custom primary key" do
    courier = Courier.new
    courier.courier_id = 139_132_750
    courier.issuer_id = 999

    character = Character.new
    character.character_id = 999
    character.name = "Mr Jones"
    character.save

    courier.issuer = character
    courier.save

    courier.issuer!.character_id.should eq 999
  end
end
