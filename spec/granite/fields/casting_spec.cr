require "../../spec_helper"

describe "#casting_to_fields" do
  it "casts string to int" do
    model = Review.new({"downvotes" => "32"})
    model.downvotes.should eq 32
  end

  it "casts time with timezone" do
    Granite.settings.default_timezone = "Asia/Shanghai"
    created_at = Time.parse("2018-12-12 00:00:00 +00:00", "%F %T %:z", Time::Location::UTC)
    model = Review.new({"created_at" => created_at})
    model.created_at.should eq Time.parse("2018-12-12 08:00:00+0800", Granite::DATETIME_FORMAT, Granite.settings.default_timezone)
  end

  it "generates an error if casting fails" do
    model = Review.new({"downvotes" => ""})
    model.errors.size.should eq 1
  end

  it "compiles with empty fields" do
    model = Empty.new
    model.should_not be_nil
  end
end
