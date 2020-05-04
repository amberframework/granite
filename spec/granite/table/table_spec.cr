require "../../spec_helper"

describe Granite::Table do
  describe ".table_name" do
    it "sets the table name to name specified" do
      CustomSongThread.table_name.should eq "custom_table_name"
    end

    it "sets the table name based on class name if not specified" do
      SongThread.table_name.should eq "song_thread"
    end

    it "strips the namespace when defining the default table now" do
      MyApp::Namespace::Model.table_name.should eq "model"
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
end
