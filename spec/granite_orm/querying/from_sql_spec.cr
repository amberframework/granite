require "../../spec_helper"

macro build_review_emitter(driver)
  {%
  timestamp = if driver == "sqlite"
    "2018-04-09 13:33:46"
  else
    "Time.now".id
  end
  %}

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
        {{ timestamp }} # created_at
      ]
    )
  end
end

def method_which_takes_any_model(model : Granite::ORM::Base.class)
  model.as(Granite::ORM::Base).from_sql build_review_emitter
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
