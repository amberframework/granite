require "./spec_helper"

describe PostgresqlAdapter do
  Spec.before_each do
    User.clear
  end

  describe "#all" do
    pending "should find all the users" do
      user = User.new
      user.name = "Test User"
      user.save
      user = User.new
      user.name = "Test User 2"
      user.save
      users = User.all
      users.size.should eq 2
    end
  end

  describe "#find" do
    pending "should find the user by id" do
      user = User.new
      user.name = "Test User"
      user.save
      id = user.id
      user = User.find id
      user.should_not be_nil 
    end
  end

  describe "#save" do
    pending "should create a new user" do
      user = User.new
      user.name = "Test User"
      user.pass = "Password"
      user.save
      user.id.should eq 1
    end

    pending "should update an existing user" do
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
    pending "should destroy a user" do
      user = User.new
      user.name = "Test User"
      user.save
      id = user.id
      user.destroy
      user = User.find id
      user.should be_nil
    end
  end

end

