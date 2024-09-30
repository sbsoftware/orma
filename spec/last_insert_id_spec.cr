require "./spec_helper"
require "sqlite3"

module Orma::LastInsertIdSpec
  class MyRecord < Orma::Record
    id_column id : Int32?
    column name : String?

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "MyRecord.save" do
    after_each do
      File.delete("./test.db")
    end

    before_each do
      MyRecord.continuous_migration!
    end

    it "should set the id after creating a new record" do
      my_record = MyRecord.new(name: "Test")

      my_record.id.value.should be_nil
      my_record.save
      my_record.id.value.should_not be_nil
    end
  end
end
