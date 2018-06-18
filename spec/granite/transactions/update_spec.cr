require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #update" do
    it "updates an object" do
      parent = Parent.new(name: "New Parent")
      parent.save!

      parent.update(name: "Other parent").should be_true
      parent.name.should eq "Other parent"
      Parent.find!(parent.id).name.should eq "Other parent"
    end

    it "does not update an invalid object" do
      parent = Parent.new(name: "New Parent")
      parent.save!

      parent.update(name: "").should be_false
      parent.name.should eq ""

      Parent.find!(parent.id).name.should eq "New Parent"
    end
  end

  describe "{{ adapter.id }} #update!" do
    it "updates an object" do
      parent = Parent.new(name: "New Parent")
      parent.save!

      parent.update!(name: "Other parent")
      parent.name.should eq "Other parent"
      Parent.find!(parent.id).name.should eq "Other parent"
    end

    it "does not update an invalid object but raises an exception" do
      parent = Parent.new(name: "New Parent")
      parent.save!

      expect_raises(Granite::RecordInvalid, "{{adapter.capitalize.id}}::Parent") do
        parent.update!(name: "")
      end
      Parent.find!(parent.id).name.should eq "New Parent"
    end
  end
end
{% end %}
