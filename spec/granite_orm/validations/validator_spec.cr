require "../../spec_helper"

class NameTest < Granite::ORM::Base
  adapter pg
  field name : String

  validate :name, "cannot be blank", ->(s : NameTest) do
    !s.name.to_s.blank?
  end
end

class EmailTest < Granite::ORM::Base
  adapter pg
  field email : String

  validate :email, "cannot be blank" do |email_test|
    !email_test.email.to_s.blank?
  end
end

class PasswordTest < Granite::ORM::Base
  adapter pg
  field password : String
  field password_validation : String

  validate "password and validation should match" do |password_test|
    password_test.password == password_test.password_validation
  end
end

describe Granite::ORM::Validators do
  describe "validates using proc" do
    it "returns true if name is set" do
      subject = NameTest.new
      subject.name = "name"
      subject.valid?.should eq true
    end

    it "returns false if name is blank" do
      subject = NameTest.new
      subject.name = ""
      subject.valid?.should eq false
    end
  end

  describe "validates using block" do
    it "returns true if email is set" do
      subject = EmailTest.new
      subject.email = "test@example.com"
      subject.valid?.should eq true
    end

    it "returns false if email is blank" do
      subject = EmailTest.new
      subject.email = ""
      subject.valid?.should eq false
    end
  end
  describe "validates using block without field" do
    it "returns true if passwords match" do
      subject = PasswordTest.new
      subject.password = "123"
      subject.password_validation = "123"
      subject.valid?.should eq true
    end

    it "returns false if password does not match" do
      subject = PasswordTest.new
      subject.password = "123"
      subject.password_validation = "1234"
      subject.valid?.should eq false
    end
  end
end
