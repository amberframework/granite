require "spec"

describe "Granite::Base track time since last write" do
  it "should switch to reader db connection after connection_switch_wait_period after write operation" do
    ReplicatedChat.connection_switch_wait_period = 250
    ReplicatedChat.new(content: "hello world!").save!
    sleep 500.milliseconds
    Fiber.current.granite_adapters.try(&.clear)
    current_url = ReplicatedChat.adapter.url
    reader_connection = Granite::Connections["#{ENV["CURRENT_ADAPTER"]}_with_replica"]
    raise "Reader connection cannot be nil" if reader_connection.nil?
    reader_url = reader_connection[:reader].url
    current_url.should eq reader_url
  end

  it "should support isolated concurrent adapter routing across fibers" do
    ReplicatedChat.switch_to_writer_adapter
    # In the main fiber, ReplicatedChat.adapter should be the writer
    ReplicatedChat.adapter.should eq ReplicatedChat.writer_adapter

    ch = Channel(Nil).new

    spawn do
      # Switch to reader in this concurrent fiber
      ReplicatedChat.switch_to_reader_adapter
      ReplicatedChat.adapter.should eq ReplicatedChat.reader_adapter
      ch.send(nil)
    end

    ch.receive

    # Back in the main fiber, it should still be the writer adapter
    ReplicatedChat.adapter.should eq ReplicatedChat.writer_adapter
  end
end
