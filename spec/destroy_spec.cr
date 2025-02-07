require "./spec_helper"
require "sqlite3"

module Orma::DestroySpec
  TEST_DB_FILE = "./test.db"

  class MyRecord < Orma::Record
    id_column id : Int32
    column name : String

    def self.db_connection_string
      "sqlite3://#{TEST_DB_FILE}"
    end
  end

  describe "MyRecord#destroy" do
    before_each do
      MyRecord.continuous_migration!
    end
    after_each do
      MyRecord.db.close
      File.delete(TEST_DB_FILE)
    end

    it "deletes the record from the database" do
      rec = MyRecord.create(name: "Test")

      MyRecord.all.count.should eq(1)

      rec.destroy

      MyRecord.all.count.should eq(0)

      expect_raises(Orma::DBError) do
        MyRecord.find(rec.id)
      end
    end
  end
end
