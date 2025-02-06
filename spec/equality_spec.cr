require "./spec_helper"

module Orma::EqualitySpec
  class MyRecord < Orma::Record
    id_column id : Int32
    column name : String
  end

  describe "#==" do
    it "should return true if the ids are equal" do
      rec1 = MyRecord.new(id: 6, name: "Helmut")

      rec2 = MyRecord.new(id: 6, name: "Dunkelmut")

      (rec1 == rec2).should be_true
    end

    it "should return false if the ids are not equal" do
      rec1 = MyRecord.new(id: 5, name: "Peter")
      rec2 = MyRecord.new(id: 6, name: "Peter")

      (rec1 == rec2).should be_false
    end
  end

  describe "Attribute#==" do
    it "should compare to the #value" do
      rec = MyRecord.new(id: 7, name: "Hans")

      rec.id.should eq(7)
      rec.name.should_not eq("Wilfried")
    end
  end
end
