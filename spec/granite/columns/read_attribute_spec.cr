require "../../spec_helper"

describe "read_attribute" do
  # Only PG supports array types
  {% if env("CURRENT_ADAPTER") == "pg" %}
    it "able to read arrays" do
      ArrayModel.new.read_attribute("i32_array").should be_nil
    end
  {% end %}
end
