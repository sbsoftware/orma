require "./spec_helper"
require "sqlite3"

module Orma::WhereSpec
  class Model < TestRecord
    id_column id : Int64
    column name : String
    column age : Int32
  end

  describe "Model.where" do
    before_each do
      Model.continuous_migration!
    end

    after_each do
      Model.db.close
    end

    it "should return the right records" do
      model1 = Model.create(name: "One", age: 10)
      model2 = Model.create(name: "Two", age: 20)

      Model.where(name: "One").to_a.should eq([model1])
      Model.where(name: "Two").to_a.should eq([model2])
    end

    it "supports multiple conditions" do
      model1 = Model.create(name: "One", age: 33)
      Model.create(name: "One", age: 10)

      Model.where(name: "One", age: 33).to_a.should eq([model1])
    end

    it "should be chainable" do
      model = Model.create(name: "Two", age: 33)
      Model.create(name: "One", age: 33)
      Model.create(name: "Two", age: 10)

      Model.where(name: "One").where(age: 33).where(name: "Two").to_a.should eq([model])
    end
  end
end
