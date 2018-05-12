require "./spec_helper"

describe Granite::Query::Builder(Model) do
  it "stores where_fields" do
    query = builder.where(name: "bob").where(age: 23)
    expected = {"name" => "bob", "age" => 23}
    query.where_fields.should eq expected
  end

  it "stores order fields" do
    query = builder.order(name: :desc).order(age: :asc)
    expected = [
      {field: "name", direction: Granite::Query::Builder::Sort::Descending},
      {field: "age", direction: Granite::Query::Builder::Sort::Ascending},
    ]
    query.order_fields.should eq expected
  end
end
