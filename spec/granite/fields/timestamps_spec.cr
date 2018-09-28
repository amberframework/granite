require "../../spec_helper"

# Can run this spec for sqlite after https://www.sqlite.org/draft/releaselog/3_24_0.html is released.
{% if ["pg", "mysql"].includes? env("CURRENT_ADAPTER") %}
  describe "timestamps" do
    it "consistently uses UTC for created_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find!(parent.id)

      original_timestamp = parent.created_at!
      read_timestamp = found_parent.created_at!

      original_timestamp.location.should eq Time::Location::UTC
      read_timestamp.location.should eq Time::Location::UTC
    end

    it "consistently uses UTC for updated_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find!(parent.id)

      original_timestamp = parent.updated_at!
      read_timestamp = found_parent.updated_at!

      original_timestamp.location.should eq Time::Location::UTC
      read_timestamp.location.should eq Time::Location::UTC
    end

    it "truncates the subsecond parts of created_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find!(parent.id)

      original_timestamp = parent.created_at!
      read_timestamp = found_parent.created_at!

      original_timestamp.epoch.should eq read_timestamp.epoch
    end

    it "truncates the subsecond parts of updated_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find!(parent.id)

      original_timestamp = parent.updated_at!
      read_timestamp = found_parent.updated_at!

      original_timestamp.epoch.should eq read_timestamp.epoch
    end

    context "bulk imports" do
      it "timestamps are returned correctly with bulk imports" do
        to_import = [
          Parent.new(name: "ParentImport1"),
          Parent.new(name: "ParentImport2"),
          Parent.new(name: "ParentImport3"),
        ]

        grandma = Parent.new(name: "grandma").tap(&.save)
        found_grandma = Parent.find! grandma.id
        Parent.import(to_import)

        parents = Parent.all("WHERE name LIKE ?", ["ParentImport%"])

        parents.size.should eq 3

        parents.each do |parent|
          parent.updated_at.not_nil!.location.should eq Time::Location::UTC
          parent.created_at.not_nil!.location.should eq Time::Location::UTC
          found_grandma.updated_at.not_nil!.epoch.should eq parent.updated_at.not_nil!.epoch
          found_grandma.created_at.not_nil!.epoch.should eq parent.created_at.not_nil!.epoch
        end
      end

      it "created_at and updated_at are correctly handled" do
        to_import = [
          Parent.new(name: "ParentOne"),
        ]

        Parent.import(to_import)
        import_time = Time.utc_now.at_beginning_of_second

        parent1 = Parent.find_by!(name: "ParentOne")
        parent1.name.should eq "ParentOne"
        parent1.created_at!.should eq import_time
        parent1.updated_at!.should eq import_time

        to_update = Parent.all("WHERE name = ?", ["ParentOne"])
        to_update.each { |parent| parent.name = "ParentOneEdited" }

        sleep 1

        Parent.import(to_update, update_on_duplicate: true, columns: ["name"])
        update_time = Time.utc_now.at_beginning_of_second

        parent1_edited = Parent.find_by!(name: "ParentOneEdited")
        parent1_edited.name.should eq "ParentOneEdited"
        parent1_edited.created_at!.should eq import_time
        parent1_edited.updated_at!.should eq update_time
      end
    end
  end
{% end %}
