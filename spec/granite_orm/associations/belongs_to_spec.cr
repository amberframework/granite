require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    teacher_constant = "Teacher#{adapter.camelcase.id}".id
    klass_constant = "Klass#{adapter.camelcase.id}".id

    adapter_suffix = "_#{adapter.id}".id
  %}

  describe "{{ adapter.id }} belongs_to" do
    it "provides a getter for the foreign entity" do
      teacher = {{ teacher_constant }}.new
      teacher.name = "Test teacher"
      teacher.save

      klass = {{ klass_constant }}.new
      klass.name = "Test klass"
      klass.teacher{{ adapter_suffix }}_id = teacher.id
      klass.save

      klass.teacher{{ adapter_suffix }}.id.should eq teacher.id
    end

    it "provides a setter for the foreign entity" do
      teacher = {{ teacher_constant }}.new
      teacher.name = "Test teacher"
      teacher.save

      klass = {{ klass_constant }}.new
      klass.name = "Test klass"
      klass.teacher{{ adapter_suffix }} = teacher
      klass.save

      klass.teacher{{ adapter_suffix }}_id.should eq teacher.id
    end
  end

{% end %}
