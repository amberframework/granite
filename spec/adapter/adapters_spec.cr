require "../spec_helper"

class Foo < Granite::Base
  adapter mysql
end

describe Granite::Adapters do
  describe "registration" do
    it "should allow adapters to be be saved and looked up" do
      Granite::Adapters.registered_adapters.size.should eq 3

      Granite::Adapters.registered_adapters.find { |adapter| adapter.name == "mysql" }.not_nil!.url.should eq ENV["MYSQL_DATABASE_URL"]
      Granite::Adapters.registered_adapters.find { |adapter| adapter.name == "pg" }.not_nil!.url.should eq ENV["PG_DATABASE_URL"]
      Granite::Adapters.registered_adapters.find { |adapter| adapter.name == "sqlite" }.not_nil!.url.should eq ENV["SQLITE_DATABASE_URL"]
    end

    it "should disallow multiple adapters with the same name" do
      expect_raises(Exception, "Adapter with name 'mysql' has already been registered.") do
        Granite::Adapters << Granite::Adapter::Pg.new({name: "mysql", url: ENV["PG_DATABASE_URL"]})
      end
    end

    it "should assign the correct adapter to a model" do
      adapter = Foo.adapter
      adapter.name.should eq "mysql"
      adapter.url.should eq ENV["MYSQL_DATABASE_URL"]
    end
  end
end
