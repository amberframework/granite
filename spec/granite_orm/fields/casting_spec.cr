# class Review{{ adapter_const_suffix }} < Granite::ORM::Base
#   field name : String
#   field downvotes : Int32
#   field upvotes : Int64
#   field sentiment : Float32
#   field interest : Float64
#   field published : Bool
#   field created_at : Time
# end

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "Review#{adapter.camelcase.id}".id %}

  describe "{{ adapter.id }} #casting_to_fields" do
    it "casts string to int" do
      model = {{ model_constant }}.new({ "downvotes" => "32" })
      model.downvotes.should eq 32
    end

    it "generates an error if casting fails" do
      model = {{ model_constant }}.new({ "downvotes" => "" })
      model.errors.size.should eq 1
    end
  end
{% end %}
