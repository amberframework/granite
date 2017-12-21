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
    Role.clear
  end

  describe "Role model with custom primary key" do
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

  describe "timestamps" do
    it "consistently uses UTC for created_at" do
      role = Parent.new(name: "test").tap(&.save)
      same_role = Parent.find(role.id).not_nil!

      original_timestamp = role.created_at.not_nil!
      read_timestamp = same_role.created_at.not_nil!

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq Time::Kind::Utc
    end

    it "consistently uses UTC for updated_at" do
      role = Parent.new(name: "test").tap(&.save)
      same_role = Parent.find(role.id).not_nil!

      original_timestamp = role.updated_at.not_nil!
      read_timestamp = same_role.updated_at.not_nil!

      original_timestamp.kind.should eq Time::Kind::Utc
      read_timestamp.kind.should eq Time::Kind::Utc
    end

    it "truncates the subsecond parts of created_at" do
      role = Parent.new(name: "test").tap(&.save)
      same_role = Parent.find(role.id).not_nil!

      original_timestamp = role.created_at.not_nil!
      read_timestamp = same_role.created_at.not_nil!

      original_timestamp.epoch_f.to_i.should eq read_timestamp.epoch
    end

    it "truncates the subsecond parts of updated_at" do
      role = Parent.new(name: "test").tap(&.save)
      same_role = Parent.find(role.id).not_nil!

      original_timestamp = role.updated_at.not_nil!
      read_timestamp = same_role.updated_at.not_nil!

      original_timestamp.epoch_f.to_i.should eq read_timestamp.epoch
    end
  end
end
