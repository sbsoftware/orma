require "sqlite3"
require "./spec_helper"

module Orma::FindSpec
  class Record < Orma::Record
    id_column id : Int64?
    column name : String

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "Record.find" do
    before_all do
      Record.continuous_migration!
      Record.new(name: "Test").save
    end

    after_all do
      File.delete("./test.db")
    end

    context "with an existing Int value" do
      it "returns the record" do
        rec = Record.find(1)
        rec.should be_a(Record)
        rec.id.should eq(1_i64)
      end
    end

    context "with a nonexisting INT value" do
      it "raises" do
        expect_raises(Orma::DBError) do
          Record.find(10)
        end
      end
    end

    context "with an existing attribute value" do
      it "returns a new instance of the record" do
        rec1 = Record.find(1)
        rec2 = Record.find(rec1.id)

        rec2.should eq(rec1)
      end
    end

    context "with a nil value" do
      it "raises" do
        expect_raises(Orma::DBError) do
          Record.find(nil)
        end
      end
    end
  end
end
