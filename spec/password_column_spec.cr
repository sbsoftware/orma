require "./spec_helper"
require "sqlite3"

module Orma::PasswordColumnSpec
  class MyModel < TestRecord
    id_column id : Int32
    password_column password
  end

  describe MyModel do
    before_each do
      MyModel.continuous_migration!
    end
    after_each do
      Orma.reset_db!
    end

    it "should save the password as a hash" do
      password = "test"
      model = MyModel.create(password: password)
      model.password_hash.should_not eq(password)
      model.password_hash.should eq(MyModel.find(model.id).password_hash)
    end

    it "should correctly verify the password" do
      password = "test"
      model = MyModel.create(password: password)
      model.verify_password(password).should be_true
      model.verify_password("other").should be_false
      model.verify_password("").should be_false
    end

    it "never verifies nil as password" do
      model = MyModel.create(password: nil)
      model.verify_password(nil).should be_false
    end

    it "accepts an internal hash without hashing it again" do
      password_hash = MyModel.generate_password_hash("test")
      model = MyModel.new(id: 1, password_hash: password_hash)

      model.password_hash.not_nil!.value.should eq(password_hash)
    end

    it "prefers the public password when both password forms are given" do
      model = MyModel.new(id: 1, password_hash: "not a hash", password: "test")

      model.password_hash.not_nil!.value.should_not eq("not a hash")
      model.verify_password("test").should be_true
    end
  end
end
