require "./spec_helper"
require "sqlite3"

module Orma::UpdateSpec
  TEST_DB_FILE = "./test.db"

  class MyRecord < Orma::Record
    id_column id : Int32
    column name : String
    column age : Int32
    column title : String?
    column created_at : Time
    column updated_at : Time

    def self.db_connection_string
      "sqlite3://#{TEST_DB_FILE}"
    end
  end

  describe "MyRecord#update" do
    before_each do
      MyRecord.continuous_migration!
    end
    after_each do
      MyRecord.db.close
      File.delete(TEST_DB_FILE)
    end

    it "assigns the given attributes" do
      rec = MyRecord.create(name: "Foo", age: 27, title: "Sir")

      rec.update(name: "Bar", age: 37, title: "Lord")

      rec.name.should eq("Bar")
      rec.age.should eq(37)
      rec.title.should eq("Lord")
    end

    it "saves the given values to the database" do
      rec = MyRecord.create(name: "Foo", age: 27, title: "Sir")

      rec.update(name: "Bar", age: 37, title: "Lord")

      rec2 = MyRecord.find(rec.id)
      rec2.name.should eq("Bar")
      rec2.age.should eq(37)
      rec2.title.should eq("Lord")
    end

    it "automatically updates updated_at" do
      rec = MyRecord.create(name: "Foo", age: 27, title: "Sir")

      old_updated_at = rec.updated_at.value
      rec.update(name: "Bar", age: 37, title: "Lord")

      [rec, MyRecord.find(rec.id)].each do |record|
        record.updated_at.should_not eq(old_updated_at)
        record.updated_at.value.should be_close(Time.utc, 1.second)
      end
    end
  end
end
