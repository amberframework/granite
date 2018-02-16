require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #find_in_batches" do
    it "finds records in batches and yields all the records" do
      model_ids = (0...100).map do |i|
        Parent.new(name: "model_#{i}").tap(&.save)
      end.map(&.id)

      found_models = [] of Int32 | Nil
      Parent.find_in_batches(batch_size: 10) do |batch|
        batch.each { |model| found_models << model.id }
        batch.size.should eq 10
      end

      found_models.compact.sort.should eq model_ids.compact
    end

    it "doesnt yield when no records are found" do
      Parent.find_in_batches do |model|
        fail "find_in_batches did yield but shouldn't have"
      end
    end

    it "errors when batch_size is < 1" do
      expect_raises ArgumentError do
        Parent.find_in_batches batch_size: 0 do |model|
          fail "should have raised"
        end
      end
    end

    it "returns a small batch when there arent enough results" do
      (0...9).each do |i|
        Parent.new(name: "model_#{i}").save
      end

      Parent.find_in_batches(batch_size: 11) do |batch|
        batch.size.should eq 9
      end
    end

    it "can start from an offset other than 0" do
      created_models = (0...10).map do |i|
        Parent.new(name: "model_#{i}").tap(&.save)
      end.map(&.id)

      # discard the first two models
      created_models.shift
      created_models.shift

      found_models = [] of Int32 | Nil

      Parent.find_in_batches(offset: 2) do |batch|
        batch.each do |model|
          found_models << model.id
        end
      end

      found_models.compact.sort.should eq created_models.compact
    end

    it "doesnt obliterate a parameterized query" do
      created_models = (0...10).map do |i|
        Parent.new(name: "model_#{i}").tap(&.save)
      end.map(&.id)

      looking_for_ids = created_models[0...5]

      Parent.find_in_batches("WHERE id IN(#{looking_for_ids.join(",")})") do |batch|
        batch.map(&.id).compact.should eq looking_for_ids
      end
    end
  end
end
{% end %}
