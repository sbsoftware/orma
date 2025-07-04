require "./spec_helper"
require "sqlite3"

module Orma::WhereSpec
  class Model < TestRecord
    column name : String
    column age : Int32
  end

  class Model2 < Orma::Record
    id_column id : Int32
    column name : String
    column age : Int32

    def self.db
      FakeDB
    end
  end

  describe "Model.where" do
    before_each do
      FakeDB.reset
    end

    after_each do
      FakeDB.assert_empty!
    end

    it "should return the right records" do
      model1 = Model.create(name: "One", age: 10)
      model2 = Model.create(name: "Two", age: 20)

      Model.where(name: "One").to_a.should eq([model1])
      Model.where(name: "Two").to_a.should eq([model2])
    end

    it "generate the correct SQL query" do
      FakeDB.expect("SELECT * FROM orma_where_spec_model2s WHERE name='One'")
      FakeDB.expect("SELECT * FROM orma_where_spec_model2s WHERE name='One' AND age=33")

      Model2.where(name: "One").to_a
      Model2.where(name: "One", age: 33).to_a
    end

    it "should be chainable" do
      FakeDB.expect("SELECT * FROM orma_where_spec_model2s WHERE name='Two' AND age=33")

      Model2.where(name: "One").where(age: 33).where(name: "Two").to_a
    end
  end
end
