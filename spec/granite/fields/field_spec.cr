require "../../spec_helper"

{% if env("CURRENT_ENV") == "pg" %}
  class Field < Granite::Base
    adapter pg

    field normal : Int32
    field! raise_on_nil : Int32
  end

  describe Granite::Fields do
    describe "field" do
      it "generates a nilable field getter and a raise-on-nil field getter suffixed with '!'" do
        field = Field.new(normal: 1)
        nil_field = Field.new

        field.normal.should eq(1)
        field.normal!.should eq(1)
        nil_field.normal.should be_nil
        expect_raises(Exception, "Field#normal cannot be nil") { nil_field.normal! }
      end
    end

    describe "field!" do
      it "generates a raise-on-nil field getter and a nilable field getter suffixed with '?'" do
        field = Field.new(raise_on_nil: 1)
        nil_field = Field.new

        field.raise_on_nil.should eq(1)
        field.raise_on_nil?.should eq(1)
        expect_raises(Exception, "Field#raise_on_nil cannot be nil") { nil_field.raise_on_nil }
        nil_field.raise_on_nil?.should be_nil
      end
    end
  end
{% end %}
