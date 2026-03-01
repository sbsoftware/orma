require "./spec_helper"

module Orma::FindEachSpec
  class MyRecord < TestRecord
    id_column id : Int64
    column name : String
  end

  describe "MyRecord.all.find_each" do
    describe "with 3 records" do
      before_each do
        MyRecord.continuous_migration!
        MyRecord.create(name: "One")
        MyRecord.create(name: "Two")
        MyRecord.create(name: "Three")
      end

      after_each do
        Orma.reset_db!
      end

      describe "with default batch_size" do
        it "should yield all records" do
          ids = [] of Int64

          MyRecord.all.find_each do |my_record|
            ids << my_record.id.value
          end

          ids.sort.should eq(MyRecord.all.map(&.id.value).sort)
        end
      end

      describe "with batch_size = 2" do
        it "should yield all records but load in two batches" do
          ids = [] of Int64

          MyRecord.all.find_each(batch_size: 2) do |my_record|
            ids << my_record.id.value
          end

          ids.sort.should eq(MyRecord.all.map(&.id.value).sort)
        end
      end
    end
  end

  describe "where scope #find_each" do
    describe "with 3 records" do
      before_each do
        MyRecord.continuous_migration!
        MyRecord.create(name: "Test")
        MyRecord.create(name: "Test")
        MyRecord.create(name: "Test")
        MyRecord.create(name: "Other")
      end

      after_each do
        Orma.reset_db!
      end

      describe "with default batch_size" do
        it "should yield all records" do
          ids = [] of Int64

          MyRecord.where({"name" => "Test"}).find_each do |my_record|
            ids << my_record.id.value
          end

          ids.size.should eq(3)
          MyRecord.where({"id" => ids}).to_a.map(&.name.value).uniq.should eq(["Test"])
        end
      end

      describe "with batch_size = 2" do
        it "should yield all records but load in two batches" do
          ids = [] of Int64

          MyRecord.where({"name" => "Test"}).find_each(batch_size: 2) do |my_record|
            ids << my_record.id.value
          end

          ids.size.should eq(3)
          MyRecord.where({"id" => ids}).to_a.map(&.name.value).uniq.should eq(["Test"])
        end
      end
    end
  end
end
