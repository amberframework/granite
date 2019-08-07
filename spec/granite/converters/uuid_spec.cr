require "../../spec_helper"

describe Granite::Converters::Uuid do
  describe String do
    describe ".to_db" do
      it "should convert a UUID enum into a String" do
        uuid = UUID.random
        Granite::Converters::Uuid(String).to_db(uuid).should eq uuid.to_s
      end
    end

    describe ".from_rs" do
      it "should convert the RS value into a UUID" do
        uuid = UUID.random
        rs = FieldEmitter.new.tap do |e|
          e._set_values([uuid.to_s])
        end

        Granite::Converters::Uuid(String).from_rs(rs).should eq uuid
      end
    end
  end

  describe Bytes do
    describe ".to_db" do
      it "should convert a UUID enum into Bytes" do
        uuid = UUID.random
        Granite::Converters::Uuid(Bytes).to_db(uuid).should eq uuid.bytes.to_slice
      end
    end

    describe ".from_rs" do
      it "should convert the RS value into a UUID" do
        uuid = UUID.new "cfe37f98-fdbf-43a3-b3d8-9c3288fb9ba6"

        rs = FieldEmitter.new.tap do |e|
          e._set_values([uuid.bytes.to_slice])
        end

        Granite::Converters::Uuid(Bytes).from_rs(rs).should eq uuid
      end
    end
  end
end
