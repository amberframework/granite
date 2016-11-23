require "./spec_helper"
require "../src/adapter/pg"

class User1 < Kemalyst::Model
  adapter pg
  sql_mapping({
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(255)", String]
  }, users)
end

# Add a new field
class User2 < Kemalyst::Model
  adapter pg
  sql_mapping({
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(255)", String],
    flag: ["BOOLEAN", Bool]
  }, users)
end

# Change type of field
class User3 < Kemalyst::Model
  adapter pg
  sql_mapping({
    name: ["VARCHAR(255)", String],
    body: ["TEXT", String],
  }, users)
end

# Change size of field
class User4 < Kemalyst::Model
  adapter pg
  sql_mapping({
    name: ["VARCHAR(255)", String],
    body: ["VARCHAR(512)", String],
  }, users)
end

describe_users = "SELECT column_name, data_type, character_maximum_length" \
" FROM information_schema.columns" \
" WHERE table_name = 'users'"

describe Kemalyst::Adapter::Pg do
  describe "#migrate" do
    it "adds any new fields" do
      User1.drop
      User1.create
      User2.migrate
      cnt = 0
      User2.query(describe_users) do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 6
    end

    context "type change" do
      it "renames the field to old_*" do
        User1.drop
        User1.create
        User3.migrate
        field = ""
        User1.query(describe_users) do |results|
          cnt = 0
          results.each do
            field = results.read(String) if cnt == 2
            cnt += 1
          end
        end
        field.should eq "old_body"
      end

      it "adds a new field" do
        User1.drop
        User1.create
        User3.migrate
        cnt = 0
        User2.query(describe_users) do |results|
          results.each { cnt += 1 }
        end
        cnt.should eq 6
      end

      it "copies the data from the old field" do
        User1.drop
        User1.create
        post = User1.new
        post.body = "Hello"
        post.save
        User3.migrate
        field = ""
        User1.query("select body from users") do |results|
          results.each do
            field = results.read(String)
          end
        end
        field.should eq "Hello"
      end
    end

    context "size change" do
      it "renames the field to old_*" do
        User1.drop
        User1.create
        User4.migrate
        field = ""
        User1.query(describe_users) do |results|
          cnt = 0
          results.each do
            field = results.read(String) if cnt == 2
            cnt += 1
          end
        end
        field.should eq "old_body"
      end

      it "adds a new field" do
        User1.drop
        User1.create
        User4.migrate
        cnt = 0
        User2.query(describe_users) do |results|
          results.each { cnt += 1 }
        end
        cnt.should eq 6
      end

      it "copies the data from the old field" do
        User1.drop
        User1.create
        post = User1.new
        post.body = "Hello"
        post.save
        User4.migrate
        field = ""
        User1.query("select body from users") do |results|
          results.each do
            field = results.read(String)
          end
        end
        field.should eq "Hello"
      end
    end
  end

  describe "#prune" do
    it "removes any fields that are not defined" do
      User2.drop
      User2.migrate
      User1.prune
      cnt = 0
      User2.query(describe_users) do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 5
    end
  end

  describe "#add_field" do
    it "adds a new field" do
      User1.drop
      User1.create
      User1.exec( User1.adapter.add_field("users", "test", "TEXT") )
      cnt = 0
      User2.query(describe_users) do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 6
    end
  end

  describe "#rename_field" do
    it "renames a field" do
      User1.drop
      User1.create
      User1.exec( User1.adapter.rename_field("users", "name", "old_name", "TEXT"))
      field = ""
      User1.query(describe_users) do |results|
        cnt = 0
        results.each do
          field = results.read(String) if cnt == 1
          cnt += 1
        end
      end
      field.should eq "old_name"
    end
  end

  describe "#remove_field" do
    it "removes a field" do
      User1.drop
      User1.create
      User1.exec(User1.adapter.remove_field("users", "name"))
      cnt = 0
      User2.query(describe_users) do |results|
        results.each { cnt += 1 }
      end
      cnt.should eq 4
    end
  end

  describe "#copy_field" do
    it "copies data from field" do
      User1.drop
      User1.create
      post = User1.new
      post.name = "Hello"
      post.save
      User1.adapter.add_field("users", "test", "VARCHAR(255)")
      User1.adapter.copy_field("users", "name", "test")
      field = ""
      User1.query("select name from users") do |results|
        results.each do
          field = results.read(String)
        end
      end
      field.should eq "Hello"
    end
  end
end

