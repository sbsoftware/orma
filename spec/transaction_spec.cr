require "./spec_helper"
require "sqlite3"

module Orma::TransactionSpec
  class FakeTxRecord < FakeRecord
    column name : String
  end

  class TxRecord < TestRecord
    id_column id : Int64
    column name : String
  end

  describe ".transaction" do
    before_each do
      TxRecord.continuous_migration!
    end

    after_each do
      TxRecord.db.close
    end

    it "commits when the block succeeds" do
      TxRecord.transaction do
        TxRecord.create(name: "committed")
      end

      TxRecord.all.to_a.size.should eq(1)
      TxRecord.all.first.name.should eq("committed")
    end

    it "rolls back when the block raises and re-raises the error" do
      expect_raises(Exception, "boom") do
        TxRecord.transaction do
          TxRecord.create(name: "rolled back")
          raise "boom"
        end
      end

      TxRecord.all.to_a.should be_empty
    end

  end

  describe "#transaction" do
    before_each do
      FakeDB.reset
    end

    after_each do
      FakeDB.assert_empty!
    end

    it "yields within the same transactional context" do
      record = FakeTxRecord.new(id: 1_i64, name: "pre")

      FakeDB.expect("UPDATE orma_transaction_spec_fake_tx_records SET name='inside' WHERE id=1")

      record.transaction do
        record.update(name: "inside")
      end
    end
  end
end
