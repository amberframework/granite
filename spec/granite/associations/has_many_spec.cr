require "../../spec_helper"

describe "has_many" do
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

    teacher.klasses.size.should eq 2
  end

  context "querying association" do
    it "#all" do
      teacher = Teacher.new
      teacher.name = "test teacher"
      teacher.save

      klass1 = Klass.new
      klass1.name = "Test class X"
      klass1.teacher = teacher
      klass1.save

      klass2 = Klass.new
      klass2.name = "Test class X"
      klass2.teacher = teacher
      klass2.save

      klass3 = Klass.new
      klass3.name = "Test class with different name"
      klass3.teacher = teacher
      klass3.save

      klasses = teacher.klasses.all("AND klasses.name = ? ORDER BY klasses.id DESC", ["Test class X"])
      klasses.map(&.id).should eq [klass2.id, klass1.id]
    end

    it "#find_by" do
      teacher = Teacher.new
      teacher.name = "test teacher"
      teacher.save

      klass1 = Klass.new
      klass1.name = "Test class X"
      klass1.teacher = teacher
      klass1.save

      klass2 = Klass.new
      klass2.name = "Test class X"
      klass2.teacher = teacher
      klass2.save

      klass3 = Klass.new
      klass3.name = "Test class with different name"
      klass3.teacher = teacher
      klass3.save

      klass = teacher.klasses.find_by(name: "Test class with different name").not_nil!
      klass.id.should eq klass3.id
      klass.name.should eq "Test class with different name"
    end

    it "#find_by!" do
      teacher = Teacher.new
      teacher.name = "test teacher"
      teacher.save

      klass1 = Klass.new
      klass1.name = "Test class X"
      klass1.teacher = teacher
      klass1.save

      klass2 = Klass.new
      klass2.name = "Test class X"
      klass2.teacher = teacher
      klass2.save

      klass3 = Klass.new
      klass3.name = "Test class with different name"
      klass3.teacher = teacher
      klass3.save

      klass = teacher.klasses.find_by!(name: "Test class with different name").not_nil!
      klass.id.should eq klass3.id
      klass.name.should eq "Test class with different name"

      expect_raises(
        Granite::Querying::NotFound,
        "No #{Klass.name} found where name = not_found"
      ) do
        klass = teacher.klasses.find_by!(name: "not_found")
      end
    end

    it "#find" do
      teacher = Teacher.new
      teacher.name = "test teacher"
      teacher.save

      klass1 = Klass.new
      klass1.name = "Test class X"
      klass1.teacher = teacher
      klass1.save

      klass2 = Klass.new
      klass2.name = "Test class X"
      klass2.teacher = teacher
      klass2.save

      klass3 = Klass.new
      klass3.name = "Test class with different name"
      klass3.teacher = teacher
      klass3.save

      klass = teacher.klasses.find(klass1.id).not_nil!
      klass.id.should eq klass1.id
      klass.name.should eq "Test class X"
    end

    it "#find!" do
      teacher = Teacher.new
      teacher.name = "test teacher"
      teacher.save

      klass1 = Klass.new
      klass1.name = "Test class X"
      klass1.teacher = teacher
      klass1.save

      klass2 = Klass.new
      klass2.name = "Test class X"
      klass2.teacher = teacher
      klass2.save

      klass3 = Klass.new
      klass3.name = "Test class with different name"
      klass3.teacher = teacher
      klass3.save

      klass = teacher.klasses.find!(klass1.id).not_nil!
      klass.id.should eq klass1.id
      klass.name.should eq "Test class X"

      id = klass3.id.as(Int64) + 42

      expect_raises(
        Granite::Querying::NotFound,
        "No #{Klass.name} found where id = #{id}"
      ) do
        teacher.klasses.find!(id)
      end
    end
  end
end
