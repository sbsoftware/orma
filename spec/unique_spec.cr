require "sqlite3"
require "./spec_helper"

module Orma::UniqueSpec
  class MyRecord < TestRecord
    id_column id : Int64
    column name : String, unique: true
  end

  class ScopedRecord < TestRecord
    id_column id : Int64
    column account_id : Int64
    column locale : String
    column slug : String, unique: {scope: [:account_id, :locale]}
  end

  class DuplicateBackfillRecord < TestRecord
    id_column id : Int64
    column tenant_id : Int64
    column slug : String, unique: {scope: [:tenant_id]}
  end

  class StringScopedRecord < TestRecord
    id_column id : Int64
    column account_id : Int64
    column slug : String, unique: {scope: ["account_id"]}
  end

  describe "MyRecord#save" do
    before_all do
      MyRecord.continuous_migration!
    end

    it "raises on attempted uniqueness violation" do
      record1 = MyRecord.create(name: "Test")

      expect_raises(Orma::DBError) do
        record2 = MyRecord.create(name: "Test")
      end
    end

    it "doesn't raise on the next continuous migration run" do
      MyRecord.continuous_migration!
    end
  end

  describe "scoped unique indexes" do
    before_all do
      ScopedRecord.continuous_migration!
    end

    it "allows duplicate values outside the configured scope" do
      ScopedRecord.create(account_id: 1_i64, locale: "en", slug: "welcome")
      ScopedRecord.create(account_id: 2_i64, locale: "en", slug: "welcome")
      ScopedRecord.create(account_id: 1_i64, locale: "de", slug: "welcome")
    end

    it "raises when all indexed values match" do
      ScopedRecord.create(account_id: 3_i64, locale: "en", slug: "welcome")

      expect_raises(Orma::DBError) do
        ScopedRecord.create(account_id: 3_i64, locale: "en", slug: "welcome")
      end
    end

    it "doesn't raise on the next continuous migration run" do
      ScopedRecord.continuous_migration!
    end
  end

  describe "continuous migration with existing duplicate data" do
    it "warns instead of raising when a new unique index conflicts with rows already in the table" do
      DuplicateBackfillRecord.ensure_table_exists!
      DuplicateBackfillRecord.db.exec "INSERT INTO #{DuplicateBackfillRecord.table_name}(id, tenant_id, slug) VALUES (1, 1, 'duplicate')"
      DuplicateBackfillRecord.db.exec "INSERT INTO #{DuplicateBackfillRecord.table_name}(id, tenant_id, slug) VALUES (2, 1, 'duplicate')"

      DuplicateBackfillRecord.continuous_migration!
    end
  end

  describe "scope column names" do
    it "accepts non-symbol literals that normalize to a column name" do
      StringScopedRecord.continuous_migration!
      StringScopedRecord.create(account_id: 1_i64, slug: "welcome")

      expect_raises(Orma::DBError) do
        StringScopedRecord.create(account_id: 1_i64, slug: "welcome")
      end
    end
  end
end
