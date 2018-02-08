require "../spec_helper"

def ignore_whitespace(expected : String)
  whitespace = "\\s+"
  compiled = expected.split(/\s/).map {|s| Regex.escape s }.join(whitespace)
  Regex.new compiled, Regex::Options::IGNORE_CASE ^ Regex::Options::MULTILINE
end

describe Query::Assembler::Postgresql(Model) do
  context "count" do
    it "adds group_by fields for where/count queries" do
      sql = "select count(*) from table where name = $1 group by name"
      builder.where(name: "bob").count.raw_sql.should match ignore_whitespace sql
    end

    it "counts without group_by fields for simple counts" do
      builder.count.raw_sql.should match ignore_whitespace "select count(*) from table"
    end
  end

  context "where" do
    it "properly numbers fields" do
      sql = "select #{query_fields} from table where name = $1 and age = $2 order by id desc"
      query = builder.where(name: "bob", age: "23")
      query.raw_sql.should match ignore_whitespace sql

      assembler = query.assembler
      assembler.build_where
      assembler.numbered_parameters.should eq ["bob", "23"]
    end
  end

  context "order" do
    it "uses default sort when no sort is provided" do
      builder.raw_sql.should match ignore_whitespace "select #{query_fields} from table order by id desc"
    end

    it "uses specified sort when provided" do
      sql = "select #{query_fields} from table order by id asc"
      builder.order(id: :asc).raw_sql.should match ignore_whitespace sql
    end
  end
end
