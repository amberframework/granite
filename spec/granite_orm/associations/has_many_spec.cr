require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
  {%
    teacher_constant    = "Teacher#{adapter.camelcase.id}".id
    klass_constant      = "Klass#{adapter.camelcase.id}".id
    student_constant    = "Student#{adapter.camelcase.id}".id
    enrollment_constant = "Enrollment#{adapter.camelcase.id}".id

    adapter_suffix = "_#{adapter.id}".id
  %}

  describe "{{ adapter.id }} has_many" do
    it "provides a method to retrieve associated objects" do
      teacher = {{ teacher_constant }}.new
      teacher.name = "test teacher"
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

    describe "#has_many, through:" do
      it "provides a method to retrieve associated objects through another table" do
        student = {{ student_constant }}.new
        student.name = "test student"
        student.save

        unrelated_student = {{ student_constant }}.new
        unrelated_student.name = "other student"
        unrelated_student.save

        klass1 = {{ klass_constant }}.new
        klass1.name = "Test class"
        klass1.save

        klass2 = {{ klass_constant }}.new
        klass2.name = "Test class"
        klass2.save

        klass3 = {{ klass_constant }}.new
        klass3.name = "Test class"
        klass3.save

        enrollment1 = {{ enrollment_constant }}.new
        enrollment1.student{{ adapter_suffix }} = student
        enrollment1.klass{{ adapter_suffix }} = klass1
        enrollment1.save

        enrollment2 = {{ enrollment_constant }}.new
        enrollment2.student{{ adapter_suffix }} = student
        enrollment2.klass{{ adapter_suffix }} = klass2
        enrollment2.save

        enrollment3 = {{ enrollment_constant }}.new
        enrollment3.klass{{ adapter_suffix }} = klass2
        enrollment3.student{{ adapter_suffix }} = unrelated_student
        enrollment3.save

        student.klass{{ adapter_suffix }}s.map(&.id).compact.sort.should eq [klass1.id, klass2.id].compact.sort

        klass2.student{{ adapter_suffix }}s.map(&.id).compact.sort.should eq [student.id, unrelated_student.id].compact.sort
      end
    end
  end

{% end %}
