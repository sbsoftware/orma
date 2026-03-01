require "./spec_helper"

module Orma::OrderSpec
  class Model < TestRecord
    id_column id : Int64
    column number : Int32
  end

  describe "Model.all.order_by_id!" do
    before_each do
      Model.continuous_migration!
    end

    after_each do
      Orma.reset_db!
    end

    it "orders by id ASC by default" do
      a = Model.create(number: 2)
      b = Model.create(number: 1)

      Model.all.order_by_id!.map(&.id.value).should eq([a.id.value, b.id.value])
    end

    it "supports directions asc and desc" do
      a = Model.create(number: 2)
      b = Model.create(number: 1)

      Model.all.order_by_id!(:desc).map(&.id.value).should eq([b.id.value, a.id.value])
    end

    it "should be chainable" do
      a = Model.create(number: 2)
      b = Model.create(number: 2)
      c = Model.create(number: 1)

      Model.all.order_by_number!(:desc).order_by_id!(:asc).map(&.id.value).should eq([a.id.value, b.id.value, c.id.value])
    end
  end
end
