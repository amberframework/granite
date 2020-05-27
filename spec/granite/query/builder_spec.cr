require "./spec_helper"

describe Granite::Query::Builder(Model) do
  it "stores where_fields" do
    query = builder.where(name: "bob").where(age: 23)
    expected = [{join: :and, field: "name", operator: :eq, value: "bob"}, {join: :and, field: "age", operator: :eq, value: 23}]
    query.where_fields.should eq expected
  end

  it "stores operators with where_fields" do
    query = builder.where(:name, :like, "bob*").where(:age, :gt, 23)
    expected = [{join: :and, field: "name", operator: :like, value: "bob*"}, {join: :and, field: "age", operator: :gt, value: 23}]
    query.where_fields.should eq expected
  end

  it "stores joins with where_fields" do
    query = builder.where(:name, :like, "bob*").or(:age, :gt, 23)
    expected = [{join: :and, field: "name", operator: :like, value: "bob*"}, {join: :or, field: "age", operator: :gt, value: 23}]
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

  it "maps array to :in" do
    query = builder.where(date_completed: nil, status: ["outstanding", "in_progress"])
    expected = [
      {join: :and, field: "date_completed", operator: :eq, value: nil},
      {join: :and, field: "status", operator: :in, value: ["outstanding", "in_progress"]},
    ]

    query.where_fields.should eq expected
  end

  it "stores limit" do
    query = builder.limit(7)
    query.limit.should eq 7
  end

  it "stores offset" do
    query = builder.offset(17)
    query.offset.should eq 17
  end

  context "raw SQL builder" do
    placeholders = {
      Granite::Query::Builder::DbType::Mysql  => "?",
      Granite::Query::Builder::DbType::Sqlite => "?",
      Granite::Query::Builder::DbType::Pg     => "$",
    }

    it "chains where statements" do
      placeholder = placeholders[builder.db_type]
      query = builder.where("name = #{placeholder}", "bob").where("age = #{placeholder}", 23)
      expected = [{join: :and, stmt: "name = #{placeholder}", value: "bob"}, {join: :and, stmt: "age = #{placeholder}", value: 23}]

      query.where_fields.should eq expected
    end

    it "chains and statements" do
      placeholder = placeholders[builder.db_type]
      query = builder.where("name = #{placeholder}", "bob").and("age = #{placeholder}", 23)
      expected = [{join: :and, stmt: "name = #{placeholder}", value: "bob"}, {join: :and, stmt: "age = #{placeholder}", value: 23}]

      query.where_fields.should eq expected
    end

    it "chains or statements" do
      placeholder = placeholders[builder.db_type]
      query = builder.where("name = #{placeholder}", "bob").or("age = #{placeholder}", 23)
      expected = [{join: :and, stmt: "name = #{placeholder}", value: "bob"}, {join: :or, stmt: "age = #{placeholder}", value: 23}]

      query.where_fields.should eq expected
    end
  end
end
