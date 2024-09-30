require "./spec_helper"
require "sqlite3"

module Orma::TimestampsSpec
  class MyRecord < Orma::Record
    id_column id : Int32?
    column name : String?
    column created_at : Time?
    column updated_at : Time?

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe MyRecord do
    before_all do
      MyRecord.continuous_migration!
    end

    after_all do
      File.delete("./test.db")
    end

    describe "#created_at" do
      it "should be set automatically on record creation" do
        my_record = MyRecord.new(name: "Test")
        my_record.save
        my_record.created_at.value.should_not be_nil

        other_instance = MyRecord.find(my_record.id)

        other_instance.created_at.value.should_not be_nil
        other_instance.created_at.value.to_s.should eq(my_record.created_at.value.to_s)

        other_instance.name = "Test2"
        other_instance.save

        other_instance.created_at.value.to_s.should eq(my_record.created_at.value.to_s)
      end
    end

    describe "#updated_at" do
      it "should be set automatically on record creation" do
        my_record = MyRecord.new(name: "Test")
        my_record.save
        my_record.updated_at.value.should_not be_nil
        my_record.updated_at.value.to_s.should eq(my_record.created_at.value.to_s)

        other_instance = MyRecord.find(my_record.id)

        other_instance.updated_at.value.should_not be_nil
        other_instance.updated_at.value.to_s.should eq(my_record.updated_at.value.to_s)
      end

      it "should be set automatically on record update" do
        my_record = MyRecord.new(name: "Test")
        my_record.save

        other_instance = MyRecord.find(my_record.id)
        other_instance.name = "Blah"
        other_instance.save

        other_instance.updated_at.value.should_not be_nil
        if (updated_at = other_instance.updated_at.value) && (old_updated_at = my_record.updated_at.value)
          updated_at.should be > old_updated_at
        end
      end
    end
  end
end
