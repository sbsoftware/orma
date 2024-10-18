require "sqlite3"
require "./spec_helper"

module Orma::IndexableSpec
  class MyRecord < Orma::Record
    id_column id : Int64?
    column name : String

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "MyRecord query objects" do
    before_all do
      MyRecord.continuous_migration!
      MyRecord.new(name: "One").save
      MyRecord.new(name: "Two").save
      MyRecord.new(name: "Three").save
    end

    after_all do
      File.delete("./test.db")
    end

    it "returns a copy of the collection from #to_a" do
      query = MyRecord.all
      arr = query.to_a
      arr.delete_at(1)

      arr2 = query.to_a

      arr.size.should eq(2)
      arr2.size.should eq(3)
    end

    it "implements #map" do
      MyRecord.all.map(&.name).should eq(["One", "Two", "Three"])
    end

    it "implements #each" do
      arr = [] of String

      MyRecord.all.each do |record|
        arr << record.name.value
      end

      arr.should eq(["One", "Two", "Three"])
    end

    it "implements #each_with_index" do
      arr = [] of Tuple(Int32, String)

      MyRecord.all.each_with_index do |record, i|
        arr << {i, record.name.value}
      end

      arr.should eq([{0, "One"}, {1, "Two"}, {2, "Three"}])
    end

    it "implements #first?" do
      MyRecord.all.first?.should eq(MyRecord.find(1))
    end

    it "implements #last?" do
      MyRecord.all.last?.should eq(MyRecord.find(3))
    end
  end
end
