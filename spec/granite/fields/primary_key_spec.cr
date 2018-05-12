{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} .new" do
    it "works when the primary is defined as `auto: true`" do
      Parent.new
    end

    it "works when the primary is defined as `auto: false`" do
      Kvs.new
    end
  end

  describe "{{ adapter.id }} .new(primary_key: value)" do
    it "ignores the value in default" do
      Parent.new(id: 1).id.should eq(nil)
    end

    it "sets the value when the primary is defined as `auto: false`" do
      Kvs.new(k: "foo").k.should eq("foo")
      Kvs.new(k: "foo", v: "v").k.should eq("foo")
    end
  end
end
{% end %}
