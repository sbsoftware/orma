require "./spec_helper"

module Orma::AssignmentSpec
  class MyRecord < Orma::Record
    id_column id : Int64?
    column name : String
    column other_record_id : Int64?
  end

  class OtherRecord < Orma::Record
    id_column id : Int64?
    column name : String
    column info : String?
  end

  describe "A record attribute" do
    context "when nilable" do
      it "can be (re)assigned other attributes or raw values" do
        my_rec = MyRecord.new(name: "Peter")
        other_rec = OtherRecord.new(id: 42_i64, name: "Paul")
        other_other_rec = OtherRecord.new(id: 6_i64, name: "Mary")
        nil_rec = OtherRecord.new(name: "Nobody")

        my_rec.other_record_id = other_rec.id
        my_rec.other_record_id.should eq(42_i64)

        my_rec.other_record_id = other_other_rec.id
        my_rec.other_record_id.should eq(6_i64)

        my_rec.other_record_id = nil_rec.id
        my_rec.other_record_id.should be_nil

        my_rec.other_record_id = 7_i64
        my_rec.other_record_id.should eq(7_i64)

        my_rec.other_record_id = nil
        my_rec.other_record_id.should be_nil
      end
    end

    context "when not nilable" do
      it "can be (re)assigned other attributes of raw values" do
        my_rec = MyRecord.new(id: 1_i64, name: "Peter")
        other_rec = OtherRecord.new(id: 42_i64, name: "Paul", info: "Perfect")
        other_other_rec = OtherRecord.new(id: 6_i64, name: "Mary")

        my_rec.name = other_rec.name
        my_rec.name.should eq("Paul")

        my_rec.name = other_other_rec.name
        my_rec.name.should eq("Mary")

        my_rec.name = "Alfred"
        my_rec.name.should eq("Alfred")
      end
    end
  end
end
