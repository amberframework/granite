require "spec"

describe "Granite::Base track time since last write" do
  it "should switch to reader db connection after connection_switch_wait_period after write operation" do
    ReplicatedChat.connection_switch_wait_period = 250
    ReplicatedChat.new(content: "hello world!").save!
    sleep 500.milliseconds
    current_url = ReplicatedChat.adapter.url
    reader_url = Granite::Connections[ENV["CURRENT_ADAPTER"] + "_with_replica"].not_nil![:reader].url
    current_url.should eq reader_url
  end
end
