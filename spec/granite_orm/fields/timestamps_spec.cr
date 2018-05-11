require "../../spec_helper"

# TODO sqlite support for timestamps
{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  {%
    avoid_macro_bug = 1 # https://github.com/crystal-lang/crystal/issues/5724

    # TODO mysql timestamp support should work better
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

    it "works with bulk imports" do
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
  end
end
{% end %}
