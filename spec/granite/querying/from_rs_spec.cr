require "../../spec_helper"

macro build_review_emitter
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
        Time.local, # created_at
      ]
    )
  end
end

def method_which_takes_any_model(model : Granite::Base.class)
  model.as(Granite::Base).from_rs build_review_emitter
end

describe ".from_rs" do
  it "Builds a model from a resultset" do
    model = Review.from_rs build_review_emitter
    model.class.should eq Review
  end
end
