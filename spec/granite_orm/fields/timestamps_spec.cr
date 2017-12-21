require "../../spec_helper"

# TODO sqlite support for timestamps
{% for adapter in ["pg", "mysql"] %}
  {%
    parent_constant = "GraniteExample::Parent#{adapter.camelcase.id}".id

    # TODO mysql timestamp support should work better
    if adapter == "pg"
      time_kind_on_read = "Time::Kind::Utc".id
    elsif adapter == "mysql"
      time_kind_on_read = "Time::Kind::Unspecified".id
    end
  %}

  describe "{{ adapter.id }} timestamps" do
    it "consistently uses UTC for created_at" do
      parent = {{ parent_constant }}.new(name: "parent").tap(&.save)
      found_parent = {{ parent_constant }}.find(parent.id).not_nil!

      original_timestamp = parent.created_at.not_nil!
      read_timestamp = found_parent.created_at.not_nil!

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq {{ time_kind_on_read }}
    end

    it "consistently uses UTC for updated_at" do
      parent = {{ parent_constant }}.new(name: "parent").tap(&.save)
      found_parent = {{ parent_constant }}.find(parent.id).not_nil!

      original_timestamp = parent.updated_at.not_nil!
      read_timestamp = found_parent.updated_at.not_nil!

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq {{ time_kind_on_read }}
    end

    it "truncates the subsecond parts of created_at" do
      parent = {{ parent_constant }}.new(name: "parent").tap(&.save)
      found_parent = {{ parent_constant }}.find(parent.id).not_nil!

      original_timestamp = parent.created_at.not_nil!
      read_timestamp = found_parent.created_at.not_nil!

      {% if adapter == "mysql" %}
        read_timestamp = Time.new read_timestamp.ticks, kind: Time::Kind::Utc
      {% end %}

      original_timestamp.epoch_f.to_i.should eq read_timestamp.epoch
    end

    it "truncates the subsecond parts of updated_at" do
      parent = {{ parent_constant }}.new(name: "parent").tap(&.save)
      found_parent = {{ parent_constant }}.find(parent.id).not_nil!

      original_timestamp = parent.updated_at.not_nil!
      read_timestamp = found_parent.updated_at.not_nil!

      {% if adapter == "mysql" %}
        read_timestamp = Time.new read_timestamp.ticks, kind: Time::Kind::Utc
      {% end %}

      original_timestamp.epoch_f.to_i.should eq read_timestamp.epoch
    end
  end
{% end %}
