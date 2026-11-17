require "./spec_helper"
require "sqlite3"

module Orma::SqliteTimePredicatesSpec
  class Event < TestRecord
    id_column id : Int64
    column occurred_at : Time?
  end

  describe "SQLite Time predicates" do
    before_each do
      Event.continuous_migration!
    end

    after_each do
      Orma.reset_db!
    end

    it "preserves submillisecond equality and inequality semantics" do
      stored = Time.utc(2025, 1, 1, 12, 0, 0, nanosecond: 123_000_000)
      event = Event.create(occurred_at: stored)
      boundary = stored + 456.microseconds

      Event.where(occurred_at: boundary).to_a.should be_empty
      Event.where(occurred_at: ...boundary).to_a.should eq([event])
      Event.where(occurred_at: boundary..).to_a.should be_empty
      Event.where(occurred_at: ..boundary).to_a.should eq([event])
      Event.where(occurred_at: (stored + 1.nanosecond)...).to_a.should be_empty
    end

    it "leaves millisecond-aligned boundaries exact" do
      stored = Time.utc(2025, 1, 1, 12, 0, 0, nanosecond: 123_000_000)
      event = Event.create(occurred_at: stored)

      Event.where(occurred_at: stored).to_a.should eq([event])
      Event.where(occurred_at: ...stored).to_a.should be_empty
      Event.where(occurred_at: stored..).to_a.should eq([event])
      Event.where(occurred_at: ..stored).to_a.should eq([event])
    end

    it "normalizes inclusive and exclusive finite ranges" do
      first = Event.create(occurred_at: Time.utc(2025, 1, 1, 12, 0, 0, nanosecond: 123_000_000))
      second = Event.create(occurred_at: Time.utc(2025, 1, 1, 12, 0, 0, nanosecond: 124_000_000))

      Event.where(occurred_at: (first.occurred_at.not_nil!.value + 456.microseconds)..(second.occurred_at.not_nil!.value + 456.microseconds)).to_a.should eq([second])
      Event.where(occurred_at: (first.occurred_at.not_nil!.value + 456.microseconds)...(second.occurred_at.not_nil!.value + 456.microseconds)).to_a.should eq([second])
    end

    it "rounds across second and day boundaries" do
      before_second = Event.create(occurred_at: Time.utc(2025, 1, 1, 23, 59, 59, nanosecond: 999_000_000))
      next_day = Event.create(occurred_at: Time.utc(2025, 1, 2, 0, 0, 0))
      boundary = before_second.occurred_at.not_nil!.value + 999.microseconds

      Event.where(occurred_at: ...boundary).to_a.should eq([before_second])
      Event.where(occurred_at: boundary..).to_a.should eq([next_day])
    end

    it "preserves NULL semantics" do
      null_event = Event.create(occurred_at: nil)
      Event.create(occurred_at: Time.utc(2025, 1, 1, 12, 0, 0, nanosecond: 123_000_000))

      Event.where(occurred_at: nil).to_a.should eq([null_event])
      Event.where(occurred_at: Time.utc(2025, 1, 1, 12, 0, 0, nanosecond: 123_456_000)).to_a.should be_empty
    end
  end
end
