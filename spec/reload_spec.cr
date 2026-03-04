require "./spec_helper"
require "sqlite3"

module Orma::ReloadSpec
  class MyRecord < TestRecord
    id_column id : Int32?
    column name : String
    column title : String?
  end

  describe "MyRecord#reload" do
    before_each do
      MyRecord.continuous_migration!
    end

    after_each do
      Orma.reset_db!
    end

    it "refreshes attributes on the same instance" do
      rec = MyRecord.create(name: "Foo", title: "Old")
      stale = MyRecord.find(rec.id)
      fresh = MyRecord.find(rec.id)
      fresh.update(name: "Bar", title: nil)

      stale.name.should eq("Foo")
      stale.title.should eq("Old")

      stale.reload

      stale.name.should eq("Bar")
      stale.title.should be_nil
      stale.id.should eq(rec.id)
    end

    it "returns self" do
      rec = MyRecord.create(name: "Foo")

      rec.reload.should be(rec)
    end

    it "raises when called without an id" do
      rec = MyRecord.new(name: "Unsaved")

      expect_raises(Exception, "Cannot reload record without `id`") do
        rec.reload
      end
    end

    it "raises when the row no longer exists" do
      rec = MyRecord.create(name: "Foo")
      rec.destroy

      expect_raises(Orma::DBError) do
        rec.reload
      end
    end
  end
end
