describe "UUID creation" do
  it "correctly sets a UUID" do
    item = Item.new(item_name: "item1")
    item.save
    item.item_id.should be_a(String)
  end
end
