require "../../spec_helper"

describe "#import" do
  describe "using the defualt primary key" do
    context "with an AUTO INCREMENT PK" do
      it "should import 3 new objects" do
        Parent.clear
        to_import = [
          Parent.new(name: "ImportParent1"),
          Parent.new(name: "ImportParent2"),
          Parent.new(name: "ImportParent3"),
        ]
        Parent.import(to_import)
        Parent.all("WHERE name LIKE ?", ["ImportParent%"]).size.should eq 3
      end

      it "should work with batch_size" do
        to_import = [
          Book.new(name: "ImportBatchBook1"),
          Book.new(name: "ImportBatchBook2"),
          Book.new(name: "ImportBatchBook3"),
          Book.new(name: "ImportBatchBook4"),
        ]

        Book.import(to_import, batch_size: 2)
        Book.all("WHERE name LIKE ?", ["ImportBatch%"]).size.should eq 4
      end

      it "should be able to update existing records" do
        to_import = [
          Review.new(name: "ImportReview1", published: false, upvotes: 0.to_i64),
          Review.new(name: "ImportReview2", published: false, upvotes: 0.to_i64),
          Review.new(name: "ImportReview3", published: false, upvotes: 0.to_i64),
          Review.new(name: "ImportReview4", published: false, upvotes: 0.to_i64),
        ]

        Review.import(to_import)

        reviews = Review.all("WHERE name LIKE ?", ["ImportReview%"])
        reviews.size.should eq 4
        reviews.none? { |r| r.published }.should be_true
        reviews.all? { |r| r.upvotes == 0 }.should be_true

        reviews.each { |r| r.published = true; r.upvotes = 1.to_i64 }

        Review.import(reviews, update_on_duplicate: true, columns: ["published", "upvotes"])

        reviews = Review.all("WHERE name LIKE ?", ["ImportReview%"])

        reviews.size.should eq 4
        reviews.all? { |r| r.published }.should be_true
        reviews.all? { |r| r.upvotes == 1 }.should be_true
      end
    end
    context "with non AUTO INCREMENT PK" do
      it "should work with on_duplicate_key_update" do
        to_import = [
          NonAutoDefaultPK.new(id: 1.to_i64, name: "NonAutoDefaultPK1"),
          NonAutoDefaultPK.new(id: 2.to_i64, name: "NonAutoDefaultPK2"),
          NonAutoDefaultPK.new(id: 3.to_i64, name: "NonAutoDefaultPK3"),
        ]

        NonAutoDefaultPK.import(to_import)

        to_import = [
          NonAutoDefaultPK.new(id: 3.to_i64, name: "NonAutoDefaultPK3"),
        ]

        NonAutoDefaultPK.import(to_import, update_on_duplicate: true, columns: ["name"])

        record = NonAutoDefaultPK.find! 3.to_i64
        record.name.should eq "NonAutoDefaultPK3"
        record.id.should eq 3.to_i64
      end

      it "should work with on_duplicate_key_ignore" do
        to_import = [
          NonAutoDefaultPK.new(id: 4.to_i64, name: "NonAutoDefaultPK4"),
          NonAutoDefaultPK.new(id: 5.to_i64, name: "NonAutoDefaultPK5"),
          NonAutoDefaultPK.new(id: 6.to_i64, name: "NonAutoDefaultPK6"),
        ]

        NonAutoDefaultPK.import(to_import)

        to_import = [
          NonAutoDefaultPK.new(id: 6.to_i64, name: "NonAutoDefaultPK6"),
        ]

        NonAutoDefaultPK.import(to_import, ignore_on_duplicate: true)

        record = NonAutoDefaultPK.find! 6.to_i64
        record.name.should eq "NonAutoDefaultPK6"
        record.id.should eq 6.to_i64
      end
    end
  end
  describe "using a custom primary key" do
    context "with an AUTO INCREMENT PK" do
      it "should import 3 new objects" do
        to_import = [
          School.new(name: "ImportBasicSchool1"),
          School.new(name: "ImportBasicSchool2"),
          School.new(name: "ImportBasicSchool3"),
        ]
        School.import(to_import)
        School.all("WHERE name LIKE ?", ["ImportBasicSchool%"]).size.should eq 3
      end

      it "should work with batch_size" do
        to_import = [
          School.new(name: "ImportBatchSchool1"),
          School.new(name: "ImportBatchSchool2"),
          School.new(name: "ImportBatchSchool3"),
          School.new(name: "ImportBatchSchool4"),
        ]

        School.import(to_import, batch_size: 2)
        School.all("WHERE name LIKE ?", ["ImportBatchSchool%"]).size.should eq 4
      end

      it "should be able to update existing records" do
        to_import = [
          School.new(name: "ImportExistingSchool"),
          School.new(name: "ImportExistingSchool"),
          School.new(name: "ImportExistingSchool"),
          School.new(name: "ImportExistingSchool"),
        ]

        School.import(to_import)

        schools = School.all("WHERE name = ?", ["ImportExistingSchool"])
        schools.size.should eq 4
        schools.all? { |s| s.name == "ImportExistingSchool" }.should be_true

        schools.each { |s| s.name = "ImportExistingSchoolEdited" }

        School.import(schools, update_on_duplicate: true, columns: ["name"])

        schools = School.all("WHERE name LIKE ?", ["ImportExistingSchool%"])
        schools.size.should eq 4
        schools.all? { |s| s.name == "ImportExistingSchoolEdited" }.should be_true
      end
    end
    context "with non AUTO INCREMENT PK" do
      it "should work with on_duplicate_key_update" do
        to_import = [
          NonAutoCustomPK.new(custom_id: 1.to_i64, name: "NonAutoCustomPK1"),
          NonAutoCustomPK.new(custom_id: 2.to_i64.to_i64, name: "NonAutoCustomPK2"),
          NonAutoCustomPK.new(custom_id: 3.to_i64, name: "NonAutoCustomPK3"),
        ]

        NonAutoCustomPK.import(to_import)

        to_import = [
          NonAutoCustomPK.new(custom_id: 3.to_i64, name: "NonAutoCustomPK3"),
        ]

        NonAutoCustomPK.import(to_import, update_on_duplicate: true, columns: ["name"])

        record = NonAutoCustomPK.find! 3.to_i64
        record.name.should eq "NonAutoCustomPK3"
        record.custom_id.should eq 3.to_i64
      end

      it "should work with on_duplicate_key_ignore" do
        to_import = [
          NonAutoCustomPK.new(custom_id: 4.to_i64, name: "NonAutoCustomPK4"),
          NonAutoCustomPK.new(custom_id: 5.to_i64, name: "NonAutoCustomPK5"),
          NonAutoCustomPK.new(custom_id: 6.to_i64, name: "NonAutoCustomPK6"),
        ]

        NonAutoCustomPK.import(to_import)

        to_import = [
          NonAutoCustomPK.new(custom_id: 6.to_i64, name: "NonAutoCustomPK6"),
        ]

        NonAutoCustomPK.import(to_import, ignore_on_duplicate: true)

        record = NonAutoCustomPK.find! 6.to_i64
        record.name.should eq "NonAutoCustomPK6"
        record.custom_id.should eq 6.to_i64
      end
    end
  end
end
