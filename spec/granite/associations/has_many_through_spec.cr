require "../../spec_helper"

describe "has_many, through:" do
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

    student.klasses.map(&.id).compact.sort.should eq [klass1.id, klass2.id].compact.sort

    klass2.students.map(&.id).compact.sort.should eq [student.id, unrelated_student.id].compact.sort
  end

  context "querying association" do
    it "#all" do
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

      klasses = student.klasses.all("AND klasses.name = ? ORDER BY klasses.id DESC", ["Test class X"])
      klasses.map(&.id).should eq [klass2.id, klass1.id]
    end

    it "#find_by" do
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

      klass = student.klasses.find_by(name: "Test class with different name").not_nil!
      klass.id.should eq klass3.id
      klass.name.should eq "Test class with different name"
    end

    it "#find_by!" do
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

      klass = student.klasses.find_by!(name: "Test class with different name").not_nil!
      klass.id.should eq klass3.id
      klass.name.should eq "Test class with different name"

      expect_raises(
        Granite::Querying::NotFound,
        "No #{Klass.name} found where name = not_found"
      ) do
        klass = student.klasses.find_by!(name: "not_found")
      end
    end

    it "#find" do
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

      klass = student.klasses.find(klass1.id).not_nil!
      klass.id.should eq klass1.id
      klass.name.should eq "Test class X"
    end

    it "#find!" do
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

      klass = student.klasses.find!(klass1.id).not_nil!
      klass.id.should eq klass1.id
      klass.name.should eq "Test class X"

      id = klass3.id.as(Int64) + 42

      expect_raises(
        Granite::Querying::NotFound,
        "No #{Klass.name} found where id = #{id}"
      ) do
        student.klasses.find!(id)
      end
    end
  end
end
