require "./spec_helper"
require "./fake_db"

module Orma::FindEachSpec
  class MyRecord < Orma::Record
    id_column id : Int32
    column name : String

    def self.db
      FakeDB
    end
  end

  describe "MyRecord.all.find_each" do
    describe "with 3 records" do
      before_each do
        FakeDB.reset
        FakeDB.expect("SELECT COUNT(*) FROM #{MyRecord.table_name}").set_result([{"count" => 3_i64} of String => DB::Any])
      end

      after_each do
        FakeDB.assert_empty!
      end

      describe "with default batch_size" do
        it "should yield all records" do
          FakeDB.expect("SELECT * FROM #{MyRecord.table_name}").set_result(
            [
              {"id" => 7, "name" => "One"} of String => DB::Any,
              {"id" => 13, "name" => "Two"} of String => DB::Any,
              {"id" => 19, "name" => "Three"} of String => DB::Any
            ]
          )

          ids = [] of Int32

          MyRecord.all.find_each do |my_record|
            if id = my_record.id.try(&.value)
              ids << id
            end
          end

          ids.should eq([7, 13, 19])
        end
      end

      describe "with batch_size = 2" do
        it "should yield all records but load in two batches" do
          FakeDB.expect("SELECT * FROM #{MyRecord.table_name} LIMIT 2 OFFSET 0").set_result(
            [
              {"id" => 7, "name" => "One"} of String => DB::Any,
              {"id" => 13, "name" => "Two"} of String => DB::Any
            ]
          )
          FakeDB.expect("SELECT * FROM #{MyRecord.table_name} LIMIT 2 OFFSET 2").set_result(
            [
              {"id" => 19, "name" => "Three"} of String => DB::Any
            ]
          )

          ids = [] of Int32

          MyRecord.all.find_each(batch_size: 2) do |my_record|
            if id = my_record.id.try(&.value)
              ids << id
            end
          end

          ids.should eq([7, 13, 19])
        end
      end
    end
  end

  describe "where scope #find_each" do
    describe "with 3 records" do
      before_each do
        FakeDB.reset
        FakeDB.expect("SELECT COUNT(*) FROM #{MyRecord.table_name} WHERE name='Test'").set_result([{"count" => 3_i64} of String => DB::Any])
      end

      after_each do
        FakeDB.assert_empty!
      end

      describe "with default batch_size" do
        it "should yield all records" do
          FakeDB.expect("SELECT * FROM #{MyRecord.table_name} WHERE name='Test'").set_result(
            [
              {"id" => 8, "name" => "Test"} of String => DB::Any,
              {"id" => 14, "name" => "Test"} of String => DB::Any,
              {"id" => 20, "name" => "Test"} of String => DB::Any
            ]
          )

          ids = [] of Int32

          MyRecord.where({"name" => "Test"}).find_each do |my_record|
            if id = my_record.id.try(&.value)
              ids << id
            end
          end

          ids.should eq([8, 14, 20])
        end
      end

      describe "with batch_size = 2" do
        it "should yield all records but load in two batches" do
          FakeDB.expect("SELECT * FROM #{MyRecord.table_name} WHERE name='Test' LIMIT 2 OFFSET 0").set_result(
            [
              {"id" => 8, "name" => "Test"} of String => DB::Any,
              {"id" => 14, "name" => "Test"} of String => DB::Any
            ]
          )
          FakeDB.expect("SELECT * FROM #{MyRecord.table_name} WHERE name='Test' LIMIT 2 OFFSET 2").set_result(
            [
              {"id" => 20, "name" => "Test"} of String => DB::Any
            ]
          )

          ids = [] of Int32

          MyRecord.where({"name" => "Test"}).find_each(batch_size: 2) do |my_record|
            if id = my_record.id.try(&.value)
              ids << id
            end
          end

          ids.should eq([8, 14, 20])
        end
      end
    end
  end
end
