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
      Orma.reset_db!
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

    it "handles SQL-like user input as plain values" do
      injected = "One' OR 1=1 --"
      model = Model.create(name: injected, age: 20)
      Model.create(name: "One", age: 10)

      Model.where(name: injected).to_a.should eq([model])
    end

    it "accepts Orma::Attribute instances as values" do
      model = Model.create(name: "One", age: 20)

      Model.where(name: model.name).to_a.should eq([model])
    end

    it "accepts arrays as values" do
      model1 = Model.create(name: "One", age: 10)
      model2 = Model.create(name: "Two", age: 20)
      Model.create(name: "Three", age: 30)

      Model.where(name: ["One", "Two"]).to_a.should eq([model1, model2])
    end

    it "handles an empty array" do
      Model.where(name: [] of String).to_a.should eq([] of Model)
    end

    it "accepts arrays of Orma::Attribute instances as values" do
      model1 = Model.create(name: "One", age: 10)
      model2 = Model.create(name: "Two", age: 20)
      Model.create(name: "Three", age: 30)

      Model.where(name: [model1.name, model2.name]).to_a.should eq([model1, model2])
    end

    it "handles an empty array of Orma::Attribute" do
      Model.where(name: [] of Orma::Attribute(String)).to_a.should eq([] of Model)
    end

    it "accepts inclusive finite ranges as values" do
      Model.create(name: "Five", age: 5)
      model1 = Model.create(name: "Ten", age: 10)
      model2 = Model.create(name: "Twenty", age: 20)
      Model.create(name: "Thirty", age: 30)

      Model.where(age: 10..20).order_by_age!.to_a.should eq([model1, model2])
    end

    it "accepts ranges in hash conditions" do
      Model.create(name: "Five", age: 5)
      model = Model.create(name: "Ten", age: 10)
      Model.create(name: "Twenty", age: 20)

      Model.where({"age" => 10...20}).to_a.should eq([model])
    end

    it "accepts ranges with mixed literal and Orma::Attribute bounds" do
      model0 = Model.create(name: "Five", age: 5)
      model1 = Model.create(name: "Ten", age: 10)
      model2 = Model.create(name: "Twenty", age: 20)
      model3 = Model.create(name: "Thirty", age: 30)

      Model.where(age: 10..Model.age(20)).order_by_age!.to_a.should eq([model1, model2])
      Model.where(age: Model.age(10)..20).order_by_age!.to_a.should eq([model1, model2])
      Model.where(age: Model.age(10)..Model.age(20)).order_by_age!.to_a.should eq([model1, model2])
      Model.where(age: Model.age(20)..).order_by_age!.to_a.should eq([model2, model3])
      Model.where(age: ..Model.age(10)).order_by_age!.to_a.should eq([model0, model1])
    end

    it "accepts exclusive finite ranges as values" do
      Model.create(name: "Five", age: 5)
      model = Model.create(name: "Ten", age: 10)
      Model.create(name: "Twenty", age: 20)

      Model.where(age: 10...20).to_a.should eq([model])
    end

    it "accepts endless ranges as values" do
      Model.create(name: "Ten", age: 10)
      model1 = Model.create(name: "Twenty", age: 20)
      model2 = Model.create(name: "Thirty", age: 30)

      Model.where(age: 20..).order_by_age!.to_a.should eq([model1, model2])
    end

    it "accepts inclusive beginless ranges as values" do
      model1 = Model.create(name: "Ten", age: 10)
      model2 = Model.create(name: "Twenty", age: 20)
      Model.create(name: "Thirty", age: 30)

      Model.where(age: ..20).order_by_age!.to_a.should eq([model1, model2])
    end

    it "accepts exclusive beginless ranges as values" do
      model = Model.create(name: "Ten", age: 10)
      Model.create(name: "Twenty", age: 20)

      Model.where(age: ...20).to_a.should eq([model])
    end
  end
end
