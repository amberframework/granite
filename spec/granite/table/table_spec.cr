require "../../spec_helper"

describe Granite::Table do
  describe ".table_name" do
    it "sets the table name to name specified" do
      CustomSongThread.table_name.should eq "custom_table_name"
    end

    it "sets the table name based on class name if not specified" do
      SongThread.table_name.should eq "song_thread"
    end
  end

  describe ".primary_name" do
    it "sets the primary key name to name specified" do
      CustomSongThread.primary_name.should eq "custom_primary_key"
    end
    it "sets the primary key name to id if not specified" do
      SongThread.primary_name.should eq "id"
    end
  end

  describe ".primary_type" do
    describe "for a custom primary key" do
      it "returns the class of the primary key's type" do
        Kvs.primary_type.should eq String
      end
    end

    describe "for the default primary key" do
      it "returns the class of the primary key's type for a defautl type" do
        Person.primary_type.should eq Int64
      end
    end
  end
end
