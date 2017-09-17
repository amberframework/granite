require "./spec_helper"
require "../src/adapter/pg"

class Parent < Granite::ORM::Base
  adapter pg

  has_many :users
  has_many :childs, through: :users

  field name : String
  timestamps
end

class User < Granite::ORM::Base
  adapter pg

  belongs_to :parent
  belongs_to :child

  field name : String
  field pass : String
  field total : Int32
  timestamps
end

class Child < Granite::ORM::Base
  adapter pg

  has_many :users
  has_many :parents, through: :users

  field name : String
end


class Role < Granite::ORM::Base
  adapter pg
  primary custom_id : Int32
  field name : String
end

Parent.exec("DROP TABLE IF EXISTS parents;")
Parent.exec("CREATE TABLE parents (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
")

User.exec("DROP TABLE IF EXISTS users;")
User.exec("CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR,
  pass VARCHAR,
  total INT,
  parent_id BIGINT,
  child_id BIGINT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
")

Child.exec("DROP TABLE IF EXISTS childs;")
Child.exec("CREATE TABLE childs (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR,
  user_id BIGINT,
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
    Parent.clear
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

    it "finds users matching clause using named substitution" do
      user = User.new
      user.name = "Bob"
      user.total = 1000
      user.save
      user = User.new
      user.name = "Joe"
      user.total = 2000
      user.save
      user = User.new
      user.name = "Joline"
      user.total = 3000
      user.save

      users = User.all("WHERE name LIKE $1", ["Jo%"])
      users.size.should eq 2
    end

    it "finds users matching clause using multiple named substitutions" do
      user = User.new
      user.name = "Bob"
      user.total = 1000
      user.save
      user = User.new
      user.name = "Joe"
      user.total = 2000
      user.save
      user = User.new
      user.name = "Joline"
      user.total = 3000
      user.save

      users = User.all("WHERE name LIKE ANY(ARRAY[$1, $2])", ["Joe%", "Joline%"])
      users.size.should eq 2
    end

    it "finds users matching clause using question mark substitution" do
      user = User.new
      user.name = "Bob"
      user.total = 1000
      user.save
      user = User.new
      user.name = "Joe"
      user.total = 2000
      user.save
      user = User.new
      user.name = "Joline"
      user.total = 3000
      user.save

      users = User.all("WHERE name LIKE ?", ["Jo%"])
      users.size.should eq 2
    end

    it "finds users matching clause using multiple question mark substitutions" do
      user = User.new
      user.name = "Bob"
      user.total = 1000
      user.save
      user = User.new
      user.name = "Joe"
      user.total = 2000
      user.save
      user = User.new
      user.name = "Joline"
      user.total = 3000
      user.save

      users = User.all("WHERE name LIKE ANY(ARRAY[?, ?])", ["Joe%", "Joline%"])
      users.size.should eq 2
    end
  end

  describe "#first" do
    it "finds the first user" do
      user1 = User.new
      user1.name = "Joe"
      user1.save
      user2 = User.new
      user2.name = "Joline"
      user2.save
      user = User.first
      user.not_nil!.id.should eq user1.id
    end

    it "supports a SQL clause" do
      user1 = User.new
      user1.name = "Joe"
      user1.save
      user2 = User.new
      user2.name = "Joline"
      user2.save
      user = User.first("ORDER BY users.name DESC")
      user.not_nil!.id.should eq user2.id
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

  describe "#belongs_to" do
    it "provides a method to retrieve parent" do
      parent = Parent.new
      parent.name = "Parent 1"
      parent.save

      user = User.new
      user.name = "Test User"
      user.pass = "password"
      user.parent_id = parent.id
      user.save

      user.parent.name.should eq "Parent 1"
    end

    it "provides a method to set parent" do
      parent = Parent.new
      parent.name = "Parent 1"
      parent.save

      user = User.new
      user.name = "Test User"
      user.pass = "password"
      user.parent = parent
      user.save

      user.parent_id.should eq parent.id
    end
  end

  describe "#has_many" do
    it "provides a method to retrieve children" do
      parent = Parent.new
      parent.name = "Parent 1"
      parent.save

      user = User.new
      user.name = "Test User 1"
      user.pass = "password"
      user.parent = parent
      user.save
      user = User.new
      user.name = "Test User 2"
      user.parent = parent
      user.save
      user = User.new
      user.name = "Test User 3"
      user.save

      parent.users.size.should eq 2
    end
  end

  describe "#has_many, through:" do
    it "provides a method to retrieve children through another table" do
      parent = Parent.new
      parent.name = "Parent 1"
      parent.save

      child = Child.new
      child.name = "Test Child"
      child.save

      user = User.new
      user.name = "Test User 1"
      user.pass = "password"
      user.parent = parent
      user.child = child
      user.save

      user = User.new
      user.name = "Test User 2"
      user.parent = parent
      user.child = child
      user.save
      user = User.new
      user.name = "Test User 3"
      user.save

      parent.childs.size.should eq 2
      child.parents.size.should eq 2
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
