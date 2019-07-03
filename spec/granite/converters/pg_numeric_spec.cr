require "../../spec_helper"

describe Granite::Converters::PgNumeric do
  describe ".to_db" do
    it "should convert a Float enum into a Float" do
      Granite::Converters::PgNumeric.to_db(3.14).should eq 3.14
    end
  end

  describe ".from_rs" do
    it "should convert the RS value into a Float64" do
      rs = FieldEmitter.new.tap do |e|
        e._set_values([PG::Numeric.new(2_i16, 0_i16, 0_i16, 1_i16, [1_i16, 3000_i16])])
      end

      Granite::Converters::PgNumeric.from_rs(rs).should eq 1.3
    end
  end
end
