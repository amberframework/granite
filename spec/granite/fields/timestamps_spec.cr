require "../../spec_helper"

# Can run this spec for sqlite after https://www.sqlite.org/draft/releaselog/3_24_0.html is released.
{% for adapter in ["pg", "mysql"] %}
module {{adapter.capitalize.id}}
  {%
    avoid_macro_bug = 1 # https://github.com/crystal-lang/crystal/issues/5724

    if adapter == "pg"
      time_kind_on_read = "Time::Kind::Utc".id
    else
      time_kind_on_read = "Time::Kind::Unspecified".id
    end
  %}

  describe "{{ adapter.id }} timestamps" do
    it "consistently uses UTC for created_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find!(parent.id)

      original_timestamp = parent.created_at!
      read_timestamp = found_parent.created_at!

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq {{ time_kind_on_read }}
    end

    it "consistently uses UTC for updated_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find!(parent.id)

      original_timestamp = parent.updated_at!
      read_timestamp = found_parent.updated_at!

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq {{ time_kind_on_read }}
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
          parent.updated_at.not_nil!.kind.should eq {{ time_kind_on_read }}
          parent.created_at.not_nil!.kind.should eq {{ time_kind_on_read }}
          found_grandma.updated_at.not_nil!.epoch.should eq parent.updated_at.not_nil!.epoch
          found_grandma.created_at.not_nil!.epoch.should eq parent.created_at.not_nil!.epoch
        end
      end

      it "created_at and updated_at are correctly handled" do
        to_import = [
          Parent.new(name: "ParentOne"),
        ]

        Parent.import(to_import)
        import_time = Time.now

        parent1 = Parent.find_by!(name: "ParentOne")
        parent1.name.should eq "ParentOne"
        parent1.created_at.not_nil!.epoch.should eq import_time.epoch
        parent1.updated_at.not_nil!.epoch.should eq import_time.epoch

        to_update = Parent.all("WHERE name = ?", ["ParentOne"])
        to_update.each { |parent| parent.name = "ParentOneEdited" }

        sleep 1

        Parent.import(to_update, update_on_duplicate: true, columns: ["name"])
        update_time = Time.now

        parent1_edited = Parent.find_by!(name: "ParentOneEdited")
        parent1_edited.name.should eq "ParentOneEdited"
        parent1_edited.created_at.not_nil!.epoch.should eq import_time.epoch
        parent1_edited.updated_at.not_nil!.epoch.should eq update_time.epoch
      end
    end
  end
end
{% end %}
