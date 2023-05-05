require "spec"

describe "Granite::Base track time since last write" do
  it "should ensure that time since last write to model is saved" do
    # This is a good way to test last write time
    # It is unlikely that the test suite takes more than an hour to run
    (Chat.time_since_last_write < 1.hours).should be_true

    # Update the time since hte last write and make sure it updated to the time within the currnet second
    Chat.update_last_write_time

    # Time since last write should be less than a second since we just updated it (see line above)
    unless (Chat.time_since_last_write < 1.second)
      raise "ERROR!!!!!"
    end
  end
end
