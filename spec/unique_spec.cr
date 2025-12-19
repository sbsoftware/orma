require "sqlite3"
require "./spec_helper"

module Orma::UniqueSpec
  class MyRecord < TestRecord
    id_column id : Int64
    column name : String, unique: true
  end

  describe "MyRecord#save" do
    before_all do
      MyRecord.continuous_migration!
    end

    it "raises on attempted uniqueness violation" do
      record1 = MyRecord.create(name: "Test")

      expect_raises(Orma::DBError) do
        record2 = MyRecord.create(name: "Test")
      end
    end

    it "doesn't raise on the next continuous migration run" do
      MyRecord.continuous_migration!
    end
  end
end
