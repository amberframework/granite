require "../../spec_helper"

describe "aggregates" do
  # Create some data points
  DataPoint.create(value1: 1_727_095_590, value2: 999_999_999_999_999_999, value3: 3.14)
  DataPoint.create(value1: 1_896_213_148, value2: 52_097_961_229, value3: 18_288_392_675.243_5)
  DataPoint.create(value1: 951_974_539, value2: 52_288_232_542, value3: 0.000_032_342_32)
  DataPoint.create(value1: 582_399_917, value2: 91_171_569_802, value3: 0.0)
  DataPoint.create(value1: 359_900_075, value2: 41_864_171_853, value3: 55_823_950_169.526)
  DataPoint.create(value1: 369_007_881, value2: 25_269_550_649, value3: -46_471_117_970.753_1)

  describe "#min" do
    it "should return the smallest value" do
      DataPoint.min(:value1, Int32).should eq 359_900_075
      DataPoint.min("value2", Int64).should eq 25_269_550_649
      DataPoint.min(:value3, Float64).should eq -46_471_117_970.753_1
    end
  end

  describe "#max" do
    it "should return the largest value" do
      DataPoint.max(:value1, Int32).should eq 1_896_213_148
      DataPoint.max("value2", Int64).should eq 999_999_999_999_999_999
      DataPoint.max(:value3, Float64).should eq 55_823_950_169.526
    end
  end

  describe "#avg" do
    it "should return the avg value" do
      DataPoint.avg(:value1, Float64).should eq 981_098_525
      DataPoint.avg("value2", Float64).should eq 1.666_667_104_485_810_2e+17
      DataPoint.avg(:value3, Float64).should eq 4_606_870_812.859_405_5
    end
  end

  describe "#sum" do
    it "should return the total value" do
      DataPoint.sum(:value1, Float64).should eq 5_886_591_150
      DataPoint.sum("value2", Float64).should eq 1_000_000_262_691_486_074
      DataPoint.sum(:value3, Float64).should eq 2.764_122_487_715_643_234_232e+10
    end
  end

  describe "#aggregate" do
    it "should allow for custom aggregate calculations" do
      DataPoint.aggregate("MIN(value1) - 75", Int64).should eq 359_900_000
      DataPoint.aggregate("(MIN(value2) / 234.234234) + 999", Float64).should eq 107_882_542.263_2
      DataPoint.aggregate("SUM(value3) - 123456789", Float64).should eq 2.751_776_808_815_643_234_232e+10
    end
  end
end