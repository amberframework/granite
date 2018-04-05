require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} has_many" do
    it "provides a method to retrieve associated objects" do
      teacher = Teacher.new
      teacher.name = "test teacher"
      teacher.save

      class1 = Klass.new
      class1.name = "Test class 1"
      class1.teacher = teacher
      class1.save

      class2 = Klass.new
      class2.name = "Test class 2"
      class2.teacher = teacher
      class2.save

      class3 = Klass.new
      class3.name = "Test class 3"
      class3.save

      teacher.klasss.size.should eq 2
    end

    it "can query the association" do
      teacher = Teacher.new
      teacher.name = "test teacher"
      teacher.save

      class1 = Klass.new
      class1.name = "Test class X"
      class1.teacher = teacher
      class1.save

      class2 = Klass.new
      class2.name = "Test class X"
      class2.teacher = teacher
      class2.save

      class3 = Klass.new
      class3.name = "Test class with different name"
      class3.teacher = teacher
      class3.save

      klasses = teacher.klasss.all("AND name = ? ORDER BY id DESC", ["Test class X"])
      klasses.map(&.id).should eq [class2.id, class1.id]

      klass = teacher.klasss.find_by(:name, "Test class with different name").not_nil!
      klass.id.should eq class3.id
      klass.name.should eq "Test class with different name"
    end

    describe "#has_many, through:" do
      it "provides a method to retrieve associated objects through another table" do
        student = Student.new
        student.name = "test student"
        student.save

        unrelated_student = Student.new
        unrelated_student.name = "other student"
        unrelated_student.save

        klass1 = Klass.new
        klass1.name = "Test class"
        klass1.save

        klass2 = Klass.new
        klass2.name = "Test class"
        klass2.save

        klass3 = Klass.new
        klass3.name = "Test class"
        klass3.save

        enrollment1 = Enrollment.new
        enrollment1.student = student
        enrollment1.klass = klass1
        enrollment1.save

        enrollment2 = Enrollment.new
        enrollment2.student = student
        enrollment2.klass = klass2
        enrollment2.save

        enrollment3 = Enrollment.new
        enrollment3.klass = klass2
        enrollment3.student = unrelated_student
        enrollment3.save

        student.klasss.map(&.id).compact.sort.should eq [klass1.id, klass2.id].compact.sort

        klass2.students.map(&.id).compact.sort.should eq [student.id, unrelated_student.id].compact.sort
      end

      it "can query the association" do
        student = Student.create(name: "test student")

        klass1 = Klass.create(name: "Test class X")
        klass2 = Klass.create(name: "Test class X")
        klass3 = Klass.create(name: "Test class with different name")

        enrollment1 = Enrollment.new
        enrollment1.student = student
        enrollment1.klass = klass1
        enrollment1.save

        enrollment2 = Enrollment.new
        enrollment2.student = student
        enrollment2.klass = klass2
        enrollment2.save

        enrollment3 = Enrollment.new
        enrollment3.klass = klass3
        enrollment3.student = student
        enrollment3.save

        klasses = student.klasss.all("AND klasss.name = ? ORDER BY klasss.id DESC", ["Test class X"])
        klasses.map(&.id).should eq [klass2.id, klass1.id]

        klass = student.klasss.find_by(:name, "Test class with different name").not_nil!
        klass.id.should eq klass3.id
        klass.name.should eq "Test class with different name"
      end
    end
  end
end
{% end %}
