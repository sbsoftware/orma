require "./spec_helper"
require "sqlite3"

module Orma::PasswordColumnSpec
  class MyModel < TestRecord
    id_column id : Int32
    password_column password
  end

  class ExplicitCostModel < TestRecord
    id_column id : Int32
    password_column password, cost: 5
  end

  describe MyModel do
    before_each do
      MyModel.password_bcrypt_cost = 4
      MyModel.continuous_migration!
    end
    after_each do
      MyModel.password_bcrypt_cost = nil
      ExplicitCostModel.password_bcrypt_cost = nil
      Orma.bcrypt_cost = nil
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

    it "uses the global bcrypt cost" do
      MyModel.password_bcrypt_cost = nil
      Orma.bcrypt_cost = 5

      Crypto::Bcrypt::Password.new(MyModel.generate_password_hash("test").not_nil!).cost.should eq(5)
    end

    it "prefers the explicit column cost over the global cost" do
      Orma.bcrypt_cost = 6

      Crypto::Bcrypt::Password.new(ExplicitCostModel.generate_password_hash("test").not_nil!).cost.should eq(5)
    end

    it "prefers the model override over the explicit column cost" do
      Orma.bcrypt_cost = 6
      ExplicitCostModel.password_bcrypt_cost = 4

      Crypto::Bcrypt::Password.new(ExplicitCostModel.generate_password_hash("test").not_nil!).cost.should eq(4)
    end

    it "uses the bcrypt library default when no cost is configured" do
      MyModel.password_bcrypt_cost = nil

      Crypto::Bcrypt::Password.new(MyModel.generate_password_hash("test").not_nil!).cost.should eq(Crypto::Bcrypt::DEFAULT_COST)
    end
  end
end
