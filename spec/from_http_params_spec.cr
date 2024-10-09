require "./spec_helper"
require "sqlite3"

module Orma::FromHttpParamsSpec
  class MyModel < Orma::Record
    id_column id : Int32?
    column name : String
    column identifier : String
    column age : Int32?
    column big_age : Int64?
    column admin : Bool = false
    column created_at : Time?
    password_column password

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe MyModel do
    before_all do
      MyModel.continuous_migration!
    end

    after_all do
      File.delete("./test.db")
    end

    describe "MyModel.from_http_params" do
      it "should create a new instance" do
        params = URI::Params.encode({name: "X", identifier: "1234", age: "32", big_age: "123412345123456", admin: "true", created_at: "2024-08-26T22:07:35Z", password: "test"})
        my_model = MyModel.from_http_params(params)
        my_model.save

        # reload
        my_model = MyModel.find(my_model.id)
        my_model.should_not be_nil

        if my_model
          my_model.id.should_not be_nil
          my_model.name.should eq("X")
          my_model.identifier.should eq("1234")
          my_model.age.should eq(32)
          my_model.big_age.should eq(123412345123456)
          my_model.admin.should be_true
          my_model.created_at.should eq(Time.utc(2024, 8, 26, 22, 7, 35))
          my_model.verify_password("test").should be_true
        end
      end
    end

    describe "MyModel#assign_http_params" do
      it "should assign attributes to an existing instance" do
        my_model = MyModel.new(name: "Test", identifier: "xyz", password: "foo")
        my_model.save

        # reload
        my_model = MyModel.find(my_model.id)
        my_model.should_not be_nil

        params = URI::Params.encode({name: "X", identifier: "1234", age: "32", big_age: "123412345123456", admin: "true", created_at: "2024-08-26T22:07:35Z", password: "test"})
        my_model.assign_http_params(params)

        if my_model
          my_model.name.should eq("X")
          my_model.identifier.should eq("1234")
          my_model.age.should eq(32)
          my_model.big_age.should eq(123412345123456)
          my_model.admin.should be_true
          my_model.created_at.should eq(Time.utc(2024, 8, 26, 22, 7, 35))
          my_model.verify_password("test").should be_true
        end
      end
    end
  end
end
