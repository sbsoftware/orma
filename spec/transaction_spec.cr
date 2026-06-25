require "./spec_helper"
require "sqlite3"

module Orma::TransactionSpec
  class TxRecord < TestRecord
    id_column id : Int64
    column name : String
  end

  describe ".transaction" do
    before_each do
      TxRecord.continuous_migration!
    end

    after_each do
      Orma.reset_db!
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

    it "returns the block value without a nilable type" do
      value = TxRecord.transaction { 1 }

      (value + 1).should eq(2)
    end
  end

  describe "#transaction" do
    before_each do
      TxRecord.continuous_migration!
    end

    after_each do
      Orma.reset_db!
    end

    it "yields within the same transactional context" do
      record = TxRecord.create(name: "pre")

      record.transaction do
        record.update(name: "inside")
      end

      TxRecord.find(record.id).name.should eq("inside")
    end

    it "returns the block value without a nilable type" do
      record = TxRecord.create(name: "pre")

      value = record.transaction { 1 }

      (value + 1).should eq(2)
    end
  end

  describe "#with_lock" do
    before_each do
      TxRecord.continuous_migration!
    end

    after_each do
      Orma.reset_db!
    end

    it "runs the block inside a transaction after locking and reloading the record" do
      record = TxRecord.create(name: "pre")
      stale = TxRecord.find(record.id)
      record.update(name: "fresh")

      stale.with_lock do
        stale.name.should eq("fresh")
        stale.update(name: "inside")
      end

      TxRecord.find(record.id).name.should eq("inside")
    end

    it "rolls back writes from the block when it raises" do
      record = TxRecord.create(name: "pre")

      expect_raises(Exception, "boom") do
        record.with_lock do
          record.update(name: "inside")
          raise "boom"
        end
      end

      TxRecord.find(record.id).name.should eq("pre")
    end

    it "returns the block value without a nilable type" do
      record = TxRecord.create(name: "pre")

      value = record.with_lock { 1 }

      (value + 1).should eq(2)
    end
  end
end
