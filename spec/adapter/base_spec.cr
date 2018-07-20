require "../spec_helper"

Granite::Settings.adapters << Granite::Adapter::Pg.new({name: "FooBar123", url: "FAKE_DB"})

class Foo < Granite::Base
  adapter FooBar123
end

describe Granite::Adapter::Base do
  describe "registration" do
    it "should allow adapters to be registered" do
      Granite::Settings.adapters.size.should eq 4

      if mysql_adatper = Granite::Settings.adapters.find { |adapter| adapter.name == "mysql" }
        mysql_adatper.url.should eq ENV["MYSQL_DATABASE_URL"]
      end
      if pg_adatper = Granite::Settings.adapters.find { |adapter| adapter.name == "pg" }
        pg_adatper.url.should eq ENV["PG_DATABASE_URL"]
      end
      if sqlite_adapter = Granite::Settings.adapters.find { |adapter| adapter.name == "sqlite" }
        sqlite_adapter.url.should eq ENV["SQLITE_DATABASE_URL"]
      end
      if foo_adapter = Granite::Settings.adapters.find { |adapter| adapter.name == "FooBar123" }
        foo_adapter.url.should eq "FAKE_DB"
      end
    end

    it "should disallow adapters multiple adapters with the same name" do
      expect_raises(Exception, "Adapter with name 'mysql' has already been registered.") do
        Granite::Settings.adapters << Granite::Adapter::Pg.new({name: "mysql", url: "PG_DATABASE_URL"})
      end
    end

    it "should assign the correct adapter to a model" do
      adapter = Foo.adapter
      adapter.name.should eq "FooBar123"
      adapter.url.should eq "FAKE_DB"
    end
  end
end
