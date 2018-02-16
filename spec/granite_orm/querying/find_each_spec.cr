require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} #find_each" do
    it "finds all the records" do
      model_ids = (0...100).map do |i|
        Parent.new(name: "role_#{i}").tap {|r| r.save }
      end.map(&.id)

      found_roles = [] of Int64 | Nil
      Parent.find_each do |model|
        found_roles << model.id
      end

      found_roles.compact.sort.should eq model_ids.compact
    end

    it "doesnt yield when no records are found" do
      Parent.find_each do |model|
        fail "did yield"
      end
    end

    it "can start from an offset" do
      created_models = (0...10).map do |i|
        Parent.new(name: "model_#{i}").tap(&.save)
      end.map(&.id)

      # discard the first two models
      created_models.shift
      created_models.shift

      found_models = [] of Int64 | Nil

      Parent.find_each(offset: 2) do |model|
        found_models << model.id
      end

      found_models.compact.sort.should eq created_models.compact
    end

    it "doesnt obliterate a parameterized query" do
      created_models = (0...10).map do |i|
        Parent.new(name: "model_#{i}").tap(&.save)
      end.map(&.id)

      looking_for_ids = created_models[0...5]

      found_models = [] of Int64 | Nil
      Parent.find_each("WHERE id IN(#{looking_for_ids.join(",")})") do |model|
        found_models << model.id
      end

      found_models.compact.should eq looking_for_ids
    end
  end
end
{% end %}
