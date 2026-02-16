require "./spec_helper"

module Orma::LimitSpec
  class Model < TestRecord
    id_column id : Int64
    column name : String
  end

  describe "Model.all.limit" do
    before_each do
      Model.continuous_migration!
      Model.create(name: "One")
      Model.create(name: "Two")
      Model.create(name: "Three")
    end

    after_each do
      Model.db.close
    end

    it "adds a LIMIT clause to the query" do
      Model.all.order_by_id!.limit(2).map(&.name.value).should eq(["One", "Two"])
    end

    it "overwrites the previous limit when called twice" do
      Model.all.order_by_id!.limit(1).limit(2).map(&.name.value).should eq(["One", "Two"])
    end

    it "unsets the limit when called with nil" do
      Model.all.order_by_id!.limit(1).limit(nil).map(&.name.value).should eq(["One", "Two", "Three"])
    end
  end
end
