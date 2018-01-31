require "../../spec_helper"

def build_review_emitter
  FieldEmitter.new.tap do |e|
    e._set_values(
      [
        8_i64,
        "name",
        nil,        # downvotes
        nil,        # upvotes
        nil,        # sentiment
        nil,        # interest
        true,       # published
        nil         # created_at
      ]
    )
  end
end

def method_which_takes_any_model(model : Granite::ORM::Base.class)
  model.as(Granite::ORM::Base).from_sql build_review_emitter
end

{% for adapter in GraniteExample::ADAPTERS %}
  {% model_constant = "Review#{adapter.camelcase.id}".id %}

  describe "{{ adapter.id }} #from_sql" do
    it "Builds a model from a resultset" do
      model = {{ model_constant }}.from_sql build_review_emitter
      model.class.should eq {{ model_constant }}
    end
  end
{% end %}
