require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} (callback feature)" do
    describe "#save (new record)" do
      it "runs before_save, before_create, after_create, after_save" do
        callback = Callback.new(name: "foo")
        callback.save

        callback.history.to_s.strip.should eq <<-EOF
          before_save
          before_create
          after_create
          after_save
          EOF
      end
    end

    describe "#save" do
      it "runs before_save, before_update, after_update, after_save" do
        Callback.new(name: "foo").save
        callback = Callback.first!
        callback.save

        callback.history.to_s.strip.should eq <<-EOF
          before_save
          before_update
          after_update
          after_save
          EOF
      end
    end

    describe "#destroy" do
      it "runs before_destroy, after_destroy" do
        Callback.new(name: "foo").save
        callback = Callback.first!
        callback.destroy

        callback.history.to_s.strip.should eq <<-EOF
          before_destroy
          after_destroy
          EOF
      end
    end

    describe "an exception thrown in a hook" do
      it "should not get swallowed" do
        callback = Callback.new(name: "foo")
        # close IO in order to raise IO::Error in callback blocks
        callback.history.close

        expect_raises(IO::Error, "Closed stream")  do
          callback.save
        end
      end
    end
  end
end
{% end %}
