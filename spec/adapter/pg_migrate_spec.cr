require "./spec_helper"
require "../src/adapter/pg"

class User1 < Kemalyst::Model
  adapter pg
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    pass: ["VARCHAR(255)", String]
  }, users)
end

# Add a new field
class User2 < Kemalyst::Model
  adapter pg
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    pass: ["VARCHAR(255)", String],
    flag: ["BOOLEAN", Bool]
  }, users)
end

# Change the type of field
class User3 < Kemalyst::Model
  adapter pg
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    pass: ["TEXT", String]
  }, users)
end

# Change the size of field
class User4 < Kemalyst::Model
  adapter pg
  sql_mapping({ 
    name: ["VARCHAR(255)", String],
    pass: ["VARCHAR(512)", String]
  }, users)
end

describe Kemalyst::Adapter::Pg do
  describe "#migrate" do
    it "does nothing when the same" do
      User3.drop
      User3.create
      User3.migrate
      if results = User1.query("SELECT column_name, data_type, character_maximum_length" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")
        results.size.should eq 5
      else
        raise "describe users returned nil"
      end
    end

    it "adds any new fields" do
      User1.drop
      User1.create
      User2.migrate
      if results = User1.query("SELECT column_name, data_type, character_maximum_length" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")
        results.size.should eq 6
      else
        raise "describe users returned nil"
      end
    end

    context "type change" do
      it "renames the field to old_*" do
        User1.drop
        User1.create
        User3.migrate
        if results = User1.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")
          results[2][0].should eq "old_pass"
        else
          raise "describe users returned nil"
        end
      end

      it "adds a new field" do
        User1.drop
        User1.create
        User3.migrate
        if results = User1.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")

          results.size.should eq 6
        else
          raise "describe users returned nil"
        end
      end

      it "copies the data from the old field" do
        User1.drop
        User1.create
        user = User1.new
        user.pass = "Hello"
        user.save
        User3.migrate
        if results = User1.query("select pass from users")
          results[0][0].to_s.should eq "Hello"
        else
          raise "copy data failed"
        end
      end
    end

    context "size change" do
      it "renames the field to old_*" do
        User1.drop
        User1.create
        User4.migrate
        if results = User1.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")

          results[2][0].should eq "old_pass"
        else
          raise "describe users returned nil"
        end
      end

      it "adds a new field" do
        User1.drop
        User1.create
        User4.migrate
        if results = User1.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")

          results.size.should eq 6
        else
          raise "describe users returned nil"
        end
      end

      it "copies the data from the old field" do
        User1.drop
        User1.create
        user = User1.new
        user.pass = "Hello"
        user.save
        User4.migrate
        if results = User1.query("select pass from users")
          results[0][0].to_s.should eq "Hello"
        else
          raise "copy data failed"
        end
      end
    end
  end

  describe "#prune" do
    it "removes any fields that are not defined" do
      User2.drop
      User2.migrate
      User1.prune
      if results = User2.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")
        results.size.should eq 5
      else
        raise "describe users returned null"
      end
    end
  end

  describe "#add_field" do
    it "adds a new field" do
      User1.drop
      User1.migrate
      User1.database.add_field("users", "test", "TEXT")
      if results = User1.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")
        results.size.should eq 6
      else
        raise "describe users returned nil"
      end
    end
  end

  describe "#rename_field" do
    it "renames a field" do
      User1.drop
      User1.migrate
      User1.database.rename_field("users", "name", "old_name", "TEXT")
      if results = User1.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")

        results[1][0].should eq "old_name"
      else
        raise "describe users returned nil"
      end
    end
  end

  describe "#remove_field" do
    it "removes a field" do
      User1.drop
      User1.migrate
      User1.database.remove_field("users", "name")
      if results = User1.query("SELECT column_name" \
                               " FROM information_schema.columns" \
                               " WHERE table_name = 'users'")
        results.size.should eq 4
      else
        raise "describe users returned nil"
      end
    end
  end

  describe "#copy_data" do
    it "copiss data from field" do
      User1.drop
      User1.migrate
      user = User1.new
      user.name = "Hello"
      user.save
      User1.database.add_field("users", "test", "VARCHAR(255)")
      User1.database.copy_field("users", "name", "test")
      if results = User1.query("select test from users")
        results[0][0].to_s.should eq "Hello"
      else
        raise "copy data failed"
      end
    end
  end

end

