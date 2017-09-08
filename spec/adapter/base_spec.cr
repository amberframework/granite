require "./spec_helper"
require "../src/adapter/base"

describe Granite::Adapter::Base do
  describe "#env" do
    context "no ${} exists" do
      it "should return itself" do
        url = "dummy://user:pswd@host:3333/database"
        Granite::Adapter::Base.env(url).should eq url
      end
    end

    context "one ${} exists" do
      it "should replace it with environment variable" do
        ENV["DATABASE"] = "test"
        url = "dummy://user:pswd@host:3333/${DATABASE}"
        Granite::Adapter::Base.env(url).should eq "dummy://user:pswd@host:3333/test"
      end
    end

    context "multiple ${} exists" do
      it "should replace each with correct environment variable" do
        ENV["USER"] = "user"
        ENV["PSWD"] = "pswd"
        ENV["HOST"] = "host"
        ENV["PORT"] = "3333"
        ENV["DATABASE"] = "test"
        url = "dummy://${USER}:${PSWD}@${HOST}:${PORT}/${DATABASE}"
        Granite::Adapter::Base.env(url).should eq "dummy://user:pswd@host:3333/test"
      end
    end
  end
end
