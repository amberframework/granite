{% for adapter in GraniteExample::ADAPTERS %}
  module {{adapter.capitalize.id}}
    describe "{{ adapter.id }} UUID creation" do
      it "correctly sets a UUID" do
      	item = Item.new(item_name: "item1")
      	item.save
      	item.item_id.should be_a(String)
      end
    end
  end
{% end %}
