require "./spec_helper"
require "sqlite3"

module Orma::PasswordColumnSpec
  TEST_DB_FILE = "./test.db"

  class MyModel < Orma::Record
    id_column id : Int32
    password_column password

    def self.db_connection_string
      "sqlite3://#{TEST_DB_FILE}"
    end
  end

  describe MyModel do
    before_each do
      MyModel.continuous_migration!
    end
    after_each do
      MyModel.db.close
      File.delete(TEST_DB_FILE)
    end

    it "should save the password as a hash" do
      password = "test"
      model = MyModel.create(password: password)
      model.password_hash.should_not eq(password)
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
  end
end
