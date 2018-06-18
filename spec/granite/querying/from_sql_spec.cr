require "../../spec_helper"

macro build_review_emitter(driver)
  FieldEmitter.new.tap do |e|
    e._set_values(
      [
        8_i64,
        "name",
        nil,   # downvotes
        nil,   # upvotes
        nil,   # sentiment
        nil,   # interest
        true,  # published
        Time.now, # created_at
      ]
    )
  end
end

def method_which_takes_any_model(model : Granite::Base.class)
  model.as(Granite::Base).from_sql build_review_emitter
end

{% for adapter in GraniteExample::ADAPTERS %}
  module {{ adapter.capitalize.id }}
    describe "{{ adapter.id }} #from_sql" do
      it "Builds a model from a resultset" do
        model = Review.from_sql build_review_emitter({{ adapter }})
        model.class.should eq Review
      end
    end
  end
{% end %}
