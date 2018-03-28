require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} belongs_to" do
    it "supports custom types for the join" do
      book = Book.new
      book.name = "Screw driver"
      book.save

      review = BookReview.new
      review.book = book
      review.body = "Best book ever!"
      review.save

      review.book.name.should eq "Screw driver"
    end
  end
end
{% end %}
