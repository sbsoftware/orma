require "./spec_helper"

module Orma::OrderSpec
  class Model < ::Orma::Record
    id_column id : Int64
    column number : Int32

    def self.db
      FakeDB
    end
  end

  describe "Model.all.order_by_id!" do
    before_each do
      FakeDB.reset
    end

    after_each do
      FakeDB.assert_empty!
    end

    it "should generate the correct SQL" do
      FakeDB.expect("SELECT * FROM orma_order_spec_models ORDER BY id ASC")

      Model.all.order_by_id!.to_a
    end

    it "should support directions asc and desc" do
      FakeDB.expect("SELECT * FROM orma_order_spec_models ORDER BY id DESC")

      Model.all.order_by_id!(:desc).to_a
    end

    it "should be chainable" do
      FakeDB.expect("SELECT * FROM orma_order_spec_models ORDER BY number DESC, id ASC")

      Model.all.order_by_number!(:desc).order_by_id!(:asc).to_a
    end
  end
end
