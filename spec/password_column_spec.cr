require "./spec_helper"

module Orma::PasswordColumnSpec
  class MyModel < Orma::Record
    id_column id : Int32?
    password_column password
  end

  describe MyModel do
    it "should save the password as a hash" do
      password = "test"
      model = MyModel.new
      model.password = password
      model.password_hash.should_not eq(password)
    end

    it "should correctly verify the password" do
      password = "test"
      model = MyModel.new
      model.password = password
      model.verify_password(password).should be_true
      model.verify_password("other").should be_false
      model.verify_password("").should be_false
    end
  end
end
