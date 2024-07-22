require "./spec_helper"
require "sqlite3"

module Orma::TimestampsSpec
  class MyRecord < Orma::Record
    id_column id : Int32?
    column name : String?
    column created_at : Time?

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "#created_at" do
    before_each do
      MyRecord.continuous_migration!
    end

    after_each do
      File.delete("./test.db")
    end

    it "should be set automatically on record creation" do
      my_record = MyRecord.new
      my_record.name = "Test"
      my_record.save
      my_record.created_at.should_not be_nil

      other_instance = MyRecord.find(my_record.id)

      other_instance.created_at.should_not be_nil
      other_instance.created_at.to_s.should eq(my_record.created_at.to_s)

      other_instance.name = "Test2"
      other_instance.save

      other_instance.created_at.to_s.should eq(my_record.created_at.to_s)
    end
  end
end
