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

    retrieved_profile = user.profile.not_nil!
    retrieved_profile.id.should eq profile.id
  end
end
