require "../../spec_helper"

class SongThread < Granite::ORM::Base
  adapter pg
  field name : String
end

class CustomSongThread < Granite::ORM::Base
  adapter pg
  table_name custom_table_name
  primary custom_primary_key : Int64
  field name : String
end

describe Granite::ORM::Table do
  describe "#table_name" do
    it "sets the table name to name specified" do
      CustomSongThread.table_name.should eq "custom_table_name"
    end

    it "sets the table name based on class name if not specified" do
      SongThread.table_name.should eq "song_threads"
    end
  end

  describe "#primary" do
    it "sets the primary key name to name specified" do
      CustomSongThread.primary_name.should eq "custom_primary_key"
    end
    it "sets the primary key name to id if not specified" do
      SongThread.primary_name.should eq "id"
    end
  end
end
