require "./spec_helper"
require "../src/adapter/pg"

class User < Granite::ORM
  adapter pg
  field name : String
  field pass : String
  field total : Int32
  timestamps
end

class Role < Granite::ORM
  adapter pg
  primary custom_id : Int32
  field name : String
end

User.exec("DROP TABLE IF EXISTS users;")
User.exec("CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR,
  pass VARCHAR,
  total INT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
")

Role.exec("DROP TABLE IF EXISTS roles;")
Role.exec("CREATE TABLE roles (
  custom_id SERIAL PRIMARY KEY,
  name VARCHAR
);
")

describe Granite::Adapter::Pg do
  Spec.before_each do
    User.clear
  end

  describe "#all" do
    it "finds all the users" do
      user = User.new
      user.name = "Test User"
      user.total = 10
      user.save
      user = User.new
      user.name = "Test User 2"
      user.save
      users = User.all
      users.size.should eq 2
    end
  end

  describe "#find" do
    it "finds the user by id" do
      user = User.new
      user.name = "Test User"
      user.save
      id = user.id
      user = User.find id
      user.should_not be_nil
    end
  end

  describe "#find_by" do
    it "finds the user by field" do
      user = User.new
      user.pass = "pass"
      user.save
      pass = user.pass
      user = User.find_by("pass", pass)
      user.should_not be_nil
    end

    it "finds the user by field using a symbol" do
      user = User.new
      user.pass = "pass"
      user.save
      pass = user.pass
      user = User.find_by(:pass, pass)
      user.should_not be_nil
    end
  end

  describe "#save" do
    it "creates a new user" do
      user = User.new
      user.name = "Test User"
      user.pass = "Password"
      user.save
      user.id.should_not be_nil
    end

    it "updates an existing user" do
      user = User.new
      user.name = "Test User"
      user.save
      user.name = "Test User 2"
      user.save
      user = User.find 1
      if user
        user.name.should eq "Test User 2"
      end
    end
  end

  describe "#destroy" do
    it "destroys a user" do
      user = User.new
      user.name = "Test User"
      user.save
      id = user.id
      user.destroy
      user = User.find id
      user.should be_nil
    end
  end

  describe "Role model with custom primary key" do
    Spec.before_each do
      Role.clear
    end

    describe "#find" do
      it "finds the role by custom_id" do
        role = Role.new
        role.name = "Test Role"
        role.save
        pk = role.custom_id
        role = Role.find pk
        role.should_not be_nil
      end
    end

    describe "#save" do
      it "updates an existing role" do
        role = Role.new
        role.name = "Test Role"
        role.save
        role.name = "Test Role 2"
        role.save
        role = Role.find 1
        if role
          role.name.should eq "Test Role 2"
        end
      end
    end

    describe "#destroy" do
      it "destroys a role" do
        role = Role.new
        role.name = "Test Role"
        role.save
        pk = role.custom_id
        role.destroy
        role = Role.find pk
        role.should be_nil
      end
    end
  end
end
