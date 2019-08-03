require "../spec_helper"

class Foo < Granite::Base
  connection sqlite

  column id : Int64, primary: true
end

class Bar < Granite::Base
  column id : Int64, primary: true
end

describe Granite::Connections do
  describe "registration" do
    it "should allow connections to be be saved and looked up" do
      Granite::Connections.registered_connections.size.should eq 3

      Granite::Connections["mysql"].not_nil!.url.should eq ENV["MYSQL_DATABASE_URL"]
      Granite::Connections["pg"].not_nil!.url.should eq ENV["PG_DATABASE_URL"]
      Granite::Connections["sqlite"].not_nil!.url.should eq ENV["SQLITE_DATABASE_URL"]
    end

    it "should disallow multiple connections with the same name" do
      expect_raises(Exception, "Adapter with name 'mysql' has already been registered.") do
        Granite::Connections << Granite::Adapter::Pg.new(name: "mysql", url: ENV["PG_DATABASE_URL"])
      end
    end

    it "should assign the correct connections to a model" do
      adapter = Foo.adapter
      adapter.name.should eq "sqlite"
      adapter.url.should eq ENV["SQLITE_DATABASE_URL"]
    end

    it "should use the first registered connection if none are specified" do
      adapter = Bar.adapter
      adapter.name.should eq "mysql"
      adapter.url.should eq ENV["MYSQL_DATABASE_URL"]
    end
  end
end
