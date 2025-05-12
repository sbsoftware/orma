require "./spec_helper"

module Orma::AttributeOperatorSpec
  class MyRecord < Orma::Record
    id_column id : Int32
    column name : String
    column age : Int32
    column admin : Bool
    column created_at : Time
  end

  describe "attributes" do
    it "should forward operators to the value" do
      rec = MyRecord.new(id: 1, name: "Tester", age: 7, admin: false, created_at: Time.utc(2025, 5, 12, 21, 45, 20))

      (rec.name + " (2)").should eq ("Tester (2)")
      (rec.age + 2).should eq(9)
      (rec.created_at + 5.minutes).should eq(Time.utc(2025, 5, 12, 21, 50, 20))

      (rec.admin == false).should be_true

      (rec.age - 2).should eq(5)
      (rec.created_at - 5.minutes).should eq(Time.utc(2025, 5, 12, 21, 40, 20))

      (rec.age * 4).should eq(28)
    end
  end
end
