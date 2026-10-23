require "./spec_helper"

module Orma::FloatSpec
  class Model < TestRecord
    id_column id : Int64
    column price : Float64
    column factor : Float32
  end

  describe "Float columns" do
    before_each do
      Model.continuous_migration!
    end

    after_each do
      Orma.reset_db!
    end

    it "creates, finds, updates, and filters Float64 and Float32 values" do
      model = Model.create(price: 12.5_f64, factor: 1.25_f32)

      found = Model.find(model.id)
      found.price.should eq(12.5_f64)
      found.factor.should eq(1.25_f32)

      found.update(price: 19.75_f64, factor: 2.5_f32)
      Model.where(price: 19.75_f64, factor: 2.5_f32).to_a.should eq([found])
    end

    it "maps both float types to SQLite REAL columns" do
      Model.db_type_for(Float64).should eq("REAL")
      Model.db_type_for(Float32).should eq("REAL")
    end
  end
end
