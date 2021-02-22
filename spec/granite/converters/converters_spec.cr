require "../../spec_helper"

describe Granite::Converters do
  {% if env("CURRENT_ADAPTER") == "pg" %}
    describe "#save" do
      it "should handle nil values" do
        model = ConverterModel.new
        model.save.should be_true
        model.id.should be_a Int64

        # Enums
        model.smallint_enum.should be_nil
        model.bigint_enum.should be_nil
        model.string_enum.should be_nil
        model.enum_enum.should be_nil
        model.binary_enum.should be_nil

        # Numeric
        model.numeric.should be_nil

        # JSON
        model.string_json.should be_nil
        model.string_jsonb.should be_nil
        model.binary_json.should be_nil
      end

      it "should handle actual values" do
        obj = MyType.new

        model = ConverterModel.new numeric: Math::PI.round(20)

        model.binary_json = model.string_jsonb = model.string_json = obj

        model.smallint_enum = MyEnum::Zero
        model.bigint_enum = MyEnum::One
        model.string_enum = MyEnum::Two
        model.enum_enum = MyEnum::Three
        model.binary_enum = MyEnum::Four

        model.save.should be_true
        model.id.should be_a Int64

        # Enums
        model.smallint_enum.should eq MyEnum::Zero
        model.bigint_enum.should eq MyEnum::One
        model.string_enum.should eq MyEnum::Two
        model.enum_enum.should eq MyEnum::Three
        model.binary_enum.should eq MyEnum::Four

        # Numeric
        model.numeric.should eq Math::PI.round(20)

        # JSON
        model.string_json.should eq obj
        model.string_jsonb.should eq obj
        model.binary_json.should eq obj
      end
    end

    describe "#read" do
      it "should handle nil values" do
        model = ConverterModel.new
        model.save.should be_true
        model.id.should be_a Int64

        retrieved_model = ConverterModel.find! model.id

        # Enums
        retrieved_model.smallint_enum.should be_nil
        retrieved_model.bigint_enum.should be_nil
        retrieved_model.string_enum.should be_nil
        retrieved_model.enum_enum.should be_nil
        retrieved_model.binary_enum.should be_nil

        # Numeric
        retrieved_model.numeric.should be_nil

        # JSON
        retrieved_model.string_json.should be_nil
        retrieved_model.string_jsonb.should be_nil
        retrieved_model.binary_json.should be_nil
      end

      it "should handle actual values" do
        obj = MyType.new

        model = ConverterModel.new numeric: Math::PI.round(20)

        model.binary_json = model.string_jsonb = model.string_json = obj

        model.smallint_enum = MyEnum::Zero
        model.bigint_enum = MyEnum::One
        model.string_enum = MyEnum::Two
        model.enum_enum = MyEnum::Three
        model.binary_enum = MyEnum::Four

        model.save.should be_true
        model.id.should be_a Int64

        retrieved_model = ConverterModel.find! model.id

        # Enum
        retrieved_model.smallint_enum.should eq MyEnum::Zero
        retrieved_model.bigint_enum.should eq MyEnum::One
        retrieved_model.string_enum.should eq MyEnum::Two
        retrieved_model.enum_enum.should eq MyEnum::Three
        retrieved_model.binary_enum.should eq MyEnum::Four

        # Numeric
        retrieved_model.numeric.should eq Math::PI.round(20)

        # JSON
        retrieved_model.string_json.should eq obj
        retrieved_model.string_jsonb.should eq obj
        retrieved_model.binary_json.should eq obj
      end
    end
  {% elsif env("CURRENT_ADAPTER") == "sqlite" %}
    describe "#save" do
      it "should handle nil values" do
        model = ConverterModel.new
        model.save.should be_true
        model.id.should be_a Int64

        # Enums
        model.int_enum.should be_nil
        model.string_enum.should be_nil
        model.binary_enum.should be_nil

        # JSON
        model.string_json.should be_nil
        model.binary_json.should be_nil
      end

      it "should handle actual values" do
        obj = MyType.new

        model = ConverterModel.new

        model.binary_json = model.string_json = obj

        model.int_enum = MyEnum::Zero
        model.string_enum = MyEnum::Two
        model.binary_enum = MyEnum::Four

        model.save.should be_true
        model.id.should be_a Int64

        # Enums
        model.int_enum.should eq MyEnum::Zero
        model.string_enum.should eq MyEnum::Two
        model.binary_enum.should eq MyEnum::Four

        # JSON
        model.string_json.should eq obj
        model.binary_json.should eq obj
      end
    end

    describe "#read" do
      it "should handle nil values" do
        model = ConverterModel.new
        model.save.should be_true
        model.id.should be_a Int64

        retrieved_model = ConverterModel.find! model.id

        # Enums
        retrieved_model.int_enum.should be_nil
        retrieved_model.string_enum.should be_nil
        retrieved_model.binary_enum.should be_nil

        # JSON
        retrieved_model.string_json.should be_nil
        retrieved_model.binary_json.should be_nil
      end

      it "should handle actual values" do
        obj = MyType.new

        model = ConverterModel.new

        model.binary_json = model.string_json = obj

        model.int_enum = MyEnum::Zero
        model.string_enum = MyEnum::Two
        model.binary_enum = MyEnum::Four

        model.save.should be_true
        model.id.should be_a Int64

        retrieved_model = ConverterModel.find! model.id

        # Enums
        retrieved_model.int_enum.should eq MyEnum::Zero
        retrieved_model.string_enum.should eq MyEnum::Two
        retrieved_model.binary_enum.should eq MyEnum::Four

        # JSON
        retrieved_model.string_json.should eq obj
        retrieved_model.binary_json.should eq obj
      end
    end
  {% elsif env("CURRENT_ADAPTER") == "mysql" %}
    describe "#save" do
      it "should handle nil values" do
        model = ConverterModel.new
        model.save.should be_true
        model.id.should be_a Int64

        # Enums
        model.int_enum.should be_nil
        model.string_enum.should be_nil
        model.enum_enum.should be_nil
        model.binary_enum.should be_nil

        # JSON
        model.string_json.should be_nil
        model.binary_json.should be_nil
      end

      it "should handle actual values" do
        obj = MyType.new

        model = ConverterModel.new

        model.binary_json = model.string_json = obj

        model.int_enum = MyEnum::Zero
        model.string_enum = MyEnum::Two
        model.enum_enum = MyEnum::Three
        model.binary_enum = MyEnum::Four

        model.save.should be_true
        model.id.should be_a Int64

        # Enums
        model.int_enum.should eq MyEnum::Zero
        model.string_enum.should eq MyEnum::Two
        model.enum_enum.should eq MyEnum::Three
        model.binary_enum.should eq MyEnum::Four

        # JSON
        model.string_json.should eq obj
        model.binary_json.should eq obj
      end
    end

    describe "#read" do
      it "should handle nil values" do
        model = ConverterModel.new
        model.save.should be_true
        model.id.should be_a Int64

        retrieved_model = ConverterModel.find! model.id

        # Enums
        retrieved_model.int_enum.should be_nil
        retrieved_model.string_enum.should be_nil
        retrieved_model.enum_enum.should be_nil
        retrieved_model.binary_enum.should be_nil

        # JSON
        retrieved_model.string_json.should be_nil
        retrieved_model.binary_json.should be_nil
      end

      it "should handle actual values" do
        obj = MyType.new

        model = ConverterModel.new

        model.binary_json = model.string_json = obj

        model.int_enum = MyEnum::Zero
        model.string_enum = MyEnum::Two
        model.enum_enum = MyEnum::Three
        model.binary_enum = MyEnum::Four

        model.save.should be_true
        model.id.should be_a Int64

        retrieved_model = ConverterModel.find! model.id

        # Enums
        retrieved_model.int_enum.should eq MyEnum::Zero
        retrieved_model.string_enum.should eq MyEnum::Two
        retrieved_model.enum_enum.should eq MyEnum::Three
        retrieved_model.binary_enum.should eq MyEnum::Four

        # JSON
        retrieved_model.string_json.should eq obj
        retrieved_model.binary_json.should eq obj
      end
    end
  {% end %}
end
