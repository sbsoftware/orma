require "./spec_helper"
require "sqlite3"

module Orma::CreateSpec
  TEST_DB_FILE = "./test.db"

  class MyRecord < Orma::Record
    id_column id : Int32
    column name : String
    column nickname : String?
    column age : Int32
    column admin : Bool = false
    password_column password
    # can not be set via .create
    deprecated_column legacy_info : String?
    column created_at : Time
    column updated_at : Time

    def self.db_connection_string
      "sqlite3://#{TEST_DB_FILE}"
    end
  end

  describe "MyRecord.create" do
    after_each do
      MyRecord.db.close
      File.delete(TEST_DB_FILE)
    end
    before_each do
      MyRecord.continuous_migration!
    end

    it "returns an instance of the record class" do
      rec = MyRecord.create(name: "First!", nickname: "Firsty", age: 21, admin: true)

      rec.id.should eq(1)

      [rec, MyRecord.find(rec.id)].each do |record|
        record.name.should eq("First!")
        record.nickname.should eq("Firsty")
        record.age.should eq(21)
        record.admin.should be_true
        record.legacy_info.should be_nil
        record.created_at.value.should be_close(Time.utc, 1.second)
        record.updated_at.value.should be_close(Time.utc, 1.second)
      end
    end

    it "doesn't overwrite given timestamp values" do
      time = Time.utc(1970, 1, 1, 0, 0, 0)
      rec = MyRecord.create(name: "Timey", age: Int32::MAX, admin: true, created_at: time)

      [rec, MyRecord.find(rec.id)].each do |record|
        record.created_at.value.should be_close(time, 1.second)
      end
    end

    it "can be called without optional parameters" do
      rec = MyRecord.create(name: "Second!", age: 21, admin: false)

      [rec, MyRecord.find(rec.id)].each do |record|
        record.name.should eq("Second!")
        record.nickname.should be_nil
        record.age.should eq(21)
        record.admin.should be_false
      end
    end

    it "applies default values to missing parameters" do
      rec = MyRecord.create(name: "Third", nickname: "Thirsty", age: 19)

      [rec, MyRecord.find(rec.id)].each do |record|
        record.name.should eq("Third")
        record.nickname.should eq("Thirsty")
        record.age.should eq(19)
        record.admin.should be_false
      end
    end

    it "correctly saves the password hash to the database" do
      rec = MyRecord.create(name: "Secret", age: 1, password: "test")

      [rec, MyRecord.find(rec.id)].each do |record|
        record.verify_password("test").should be_true
      end
    end
  end
end
