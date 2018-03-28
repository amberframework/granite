require "../spec_helper"

private def adapter
  Granite::Adapter::Pg.new("pg")
end

describe Granite::Adapter::Pg do
  describe "#quote" do
    context "simple value" do
      it %(should return "foo") do
        adapter.quote("foo").should eq(%("foo"))
      end
    end

    context "dotted value" do
      it %(should return "foo"."bar") do
        adapter.quote("foo.bar").should eq(%("foo"."bar"))
      end
    end

    context "already quoted value" do
      it "guarantees idempotency" do
        adapter.quote(%("foo")).should eq(%("foo"))
        adapter.quote(%("foo"."bar")).should eq(%("foo"."bar"))
      end
    end
  end
end
