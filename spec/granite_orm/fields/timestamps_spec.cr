require "../../spec_helper"

# TODO sqlite support for timestamps
{% for adapter in ["pg", "mysql"] %}
module {{adapter.capitalize.id}}
  {%
    avoid_macro_bug = 1 # https://github.com/crystal-lang/crystal/issues/5724
    
    # TODO mysql timestamp support should work better
    if adapter == "pg"
      time_kind_on_read = "Time::Kind::Utc".id
    elsif adapter == "mysql"
      time_kind_on_read = "Time::Kind::Unspecified".id
    end
  %}

  describe "{{ adapter.id }} timestamps" do
    it "consistently uses UTC for created_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find(parent.id)

      original_timestamp = parent.created_at
      read_timestamp = found_parent.created_at

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq {{ time_kind_on_read }}
    end

    it "consistently uses UTC for updated_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find(parent.id)

      original_timestamp = parent.updated_at
      read_timestamp = found_parent.updated_at

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq {{ time_kind_on_read }}
    end

    it "truncates the subsecond parts of created_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find(parent.id)

      original_timestamp = parent.created_at
      read_timestamp = found_parent.created_at

      original_timestamp.epoch.should eq read_timestamp.epoch
    end

    it "truncates the subsecond parts of updated_at" do
      parent = Parent.new(name: "parent").tap(&.save)
      found_parent = Parent.find(parent.id)

      original_timestamp = parent.updated_at
      read_timestamp = found_parent.updated_at

      original_timestamp.epoch.should eq read_timestamp.epoch
    end
  end
end
{% end %}
