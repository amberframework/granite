require "spec"

describe "Granite::Base track time since last write" do
  it "should ensure that time since last write to model is saved" do
    # This is a good way to test last write time
    # It is unlikely that the test suite takes more than an hour to run
    (ReplicatedChat.time_since_last_write < 1.hours).should be_true

    # Update the time since last write. Ensure it updated to the time within the currnet second
    ReplicatedChat.update_last_write_time

    # Time since last write should be less than a second since we just updated it (see line above)
    unless (ReplicatedChat.time_since_last_write < 1.second)
      raise "ERROR!!!!!"
    end
  end

  it "should switch to reader db connection after connection_switch_wait_period after write operation" do
    ReplicatedChat.new(content: "hello world!").save!
    ReplicatedChat.connection_switch_wait_period = 250
    sleep ReplicatedChat.connection_switch_wait_period.milliseconds
    current_url = ReplicatedChat.adapter.url
    reader_url = Granite::Connections[ENV["CURRENT_ADAPTER"] + "_with_replica"].not_nil![:reader].url
    current_url.should eq reader_url
  end
end
