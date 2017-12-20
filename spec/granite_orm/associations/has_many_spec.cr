require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    teacher_constant = "GraniteExample::Teacher#{adapter.camelcase.id}".id
    klass_constant = "GraniteExample::Klass#{adapter.camelcase.id}".id

    adapter_suffix = "_#{adapter.id}".id
  %}

  describe "has_many with {{ adapter.id }}" do
    it "provides a method to retrieve children" do
      teacher = {{ teacher_constant }}.new
      teacher.name = "Test Thread"
      teacher.save

      class1 = {{ klass_constant }}.new
      class1.name = "Test class 1"
      class1.teacher{{ adapter_suffix }} = teacher
      class1.save

      class2 = {{ klass_constant }}.new
      class2.name = "Test class 2"
      class2.teacher{{ adapter_suffix }} = teacher
      class2.save

      class3 = {{ klass_constant }}.new
      class3.name = "Test class 3"
      class3.save

      teacher.klass{{ adapter_suffix }}s.size.should eq 2
    end
  end

{% end %}
