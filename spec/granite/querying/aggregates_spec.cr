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
      {% if env("CURRENT_ADAPTER") == "sqlite" %}
      DataPoint.min(:value1, Int64).should eq 359_900_075
      {% else %}
      DataPoint.min(:value1, Int32).should eq 359_900_075
      {% end %}
      DataPoint.min("value2", Int64).should eq 25_269_550_649
      DataPoint.min(:value3, Float64).should eq -46_471_117_970.753_1
    end

    describe "with a where clause" do
      it "should return the smallest value" do
        {% if env("CURRENT_ADAPTER") == "sqlite" %}
      DataPoint.where(:value1, :gt, 400_000_000).min(:value1, Int64).should eq 582_399_917
      {% else %}
      DataPoint.where(:value1, :gt, 400_000_000).min(:value1, Int32).should eq 582_399_917
      {% end %}
      end
    end
  end

  describe "#max" do
    it "should return the largest value" do
      {% if env("CURRENT_ADAPTER") == "sqlite" %}
      DataPoint.max(:value1, Int64).should eq 1_896_213_148
      {% else %}
      DataPoint.max(:value1, Int32).should eq 1_896_213_148
      {% end %}
      DataPoint.max("value2", Int64).should eq 999_999_999_999_999_999
      DataPoint.max(:value3, Float64).should eq 55_823_950_169.526
    end

    describe "with a where clause" do
      it "should return the largest value" do
        DataPoint.where("value2", :lt, 50_000_000_000).max(:value2, Int64).should eq 41_864_171_853
      end
    end
  end

  describe "#avg" do
    it "should return the avg value" do
      {% if env("CURRENT_ADAPTER") == "sqlite" || env("CURRENT_ADAPTER") == "mysql" %}
      DataPoint.avg(:value1, Float64).should eq 981_098_525
      DataPoint.avg("value2", Float64).should eq 1.666_667_104_485_810_2e+17
      {% else %}
      DataPoint.avg(:value1, Int32).should eq 981_098_525
      DataPoint.avg("value2", Int64).should eq 1.666_667_104_485_810_2e+17
      {% end %}
      DataPoint.avg(:value3, Float64).should eq 4_606_870_812.859_405_5
    end

    describe "with a where clause" do
      it "should return the average value" do
        DataPoint.where(:value3, :eq, 3.14).avg(:value3, Float64).should eq 3.14
      end
    end
  end

  describe "#sum" do
    it "should return the total value" do
      {% if env("CURRENT_ADAPTER") == "mysql" %}
      DataPoint.sum(:value1, Float64).should eq 5_886_591_150
      DataPoint.sum("value2", Float64).should eq 1_000_000_262_691_486_074
      {% else %}
      DataPoint.sum(:value1, Int64).should eq 5_886_591_150
      DataPoint.sum("value2", Int64).should eq 1_000_000_262_691_486_074
      {% end %}
      DataPoint.sum(:value3, Float64).should eq 2.764_122_487_715_643_234_232e+10
    end

    describe "with a where clause" do
      it "should return the total value" do
        {% if env("CURRENT_ADAPTER") == "mysql" %}
        DataPoint.where(:value1, :lteq, 369_007_881).sum(:value1, Float64).should eq 728_907_956
        {% else %}
        DataPoint.where(:value1, :lteq, 369_007_881).sum(:value1, Int64).should eq 728_907_956
        {% end %}
      end
    end
  end

  describe "#aggregate" do
    it "should allow for custom aggregate calculations" do
      {% if env("CURRENT_ADAPTER") == "sqlite" || env("CURRENT_ADAPTER") == "mysql" %}
      DataPoint.aggregate("MIN(value1) - 75", Int64).should eq 359_900_000
      {% else %}
      DataPoint.aggregate("MIN(value1) - 75", Int32).should eq 359_900_000
      {% end %}
      {% if env("CURRENT_ADAPTER") == "mysql" %}
      DataPoint.aggregate("(MIN(value2) / 234.234234) + 999", Float64).should eq 107_882_542.263_2
      {% else %}
      DataPoint.aggregate("(MIN(value2) / 234.234234) + 999", Float64).should eq 107_882_542.263_227_7
      {% end %}
      DataPoint.aggregate("SUM(value3) - 123456789", Float64).should eq 2.751_776_808_815_643_234_232e+10
    end

    describe "with a where clause" do
      it "should return the average value" do
        DataPoint.where("value3", :eq, 3.14).aggregate("10 + 15.2", Float64).should eq 25.2
      end
    end
  end
end
