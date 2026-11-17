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

  class MacroIdScopedRecord < TestRecord
    id_column id : Int64
    column account_id : Int64
    column slug : String, unique: {scope: [account_id]}
  end

  class ChangedIndexRecord < TestRecord
    id_column id : Int64
    column account_id : Int64
    column locale : String
    column slug : String, unique: {scope: [:account_id]}
  end

  class RemovedIndexRecord < TestRecord
    id_column id : Int64
    column name : String
  end

  class FailedReplacementRecord < TestRecord
    id_column id : Int64
    column account_id : Int64
    column slug : String, unique: true
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

  describe "continuous migration index pruning" do
    it "creates changed declarations before pruning obsolete managed indexes" do
      ChangedIndexRecord.ensure_table_exists!
      old_index = "idx_#{ChangedIndexRecord.table_name}_slug_account_id_locale"
      ChangedIndexRecord.db.exec "CREATE UNIQUE INDEX #{old_index} ON #{ChangedIndexRecord.table_name} (slug, account_id, locale)"

      ChangedIndexRecord.continuous_migration!

      ChangedIndexRecord.db_adapter.query_index_names(ChangedIndexRecord.table_name).sort.should eq(["idx_#{ChangedIndexRecord.table_name}_slug_account_id"])
      ChangedIndexRecord.continuous_migration!
      ChangedIndexRecord.db_adapter.query_index_names(ChangedIndexRecord.table_name).sort.should eq(["idx_#{ChangedIndexRecord.table_name}_slug_account_id"])
    end

    it "prunes removed declarations while preserving unmanaged indexes" do
      RemovedIndexRecord.ensure_table_exists!
      managed_index = "idx_#{RemovedIndexRecord.table_name}_name"
      RemovedIndexRecord.db.exec "CREATE UNIQUE INDEX #{managed_index} ON #{RemovedIndexRecord.table_name} (name)"
      RemovedIndexRecord.db.exec "CREATE INDEX manually_created_name_index ON #{RemovedIndexRecord.table_name} (name)"

      RemovedIndexRecord.continuous_migration!

      RemovedIndexRecord.db_adapter.query_index_names(RemovedIndexRecord.table_name).sort.should eq(["manually_created_name_index"])
    end

    it "retains obsolete indexes when replacement creation fails" do
      FailedReplacementRecord.ensure_table_exists!
      old_index = "idx_#{FailedReplacementRecord.table_name}_account_id"
      FailedReplacementRecord.db.exec "CREATE UNIQUE INDEX #{old_index} ON #{FailedReplacementRecord.table_name} (account_id)"
      FailedReplacementRecord.db.exec "INSERT INTO #{FailedReplacementRecord.table_name}(account_id, slug) VALUES (1, 'duplicate'), (2, 'duplicate')"

      FailedReplacementRecord.continuous_migration!

      FailedReplacementRecord.db_adapter.query_index_names(FailedReplacementRecord.table_name).should contain(old_index)
      FailedReplacementRecord.db_adapter.query_index_names(FailedReplacementRecord.table_name).should_not contain("idx_#{FailedReplacementRecord.table_name}_slug")
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

    it "accepts macro ids directly" do
      MacroIdScopedRecord.continuous_migration!
      MacroIdScopedRecord.create(account_id: 1_i64, slug: "welcome")

      expect_raises(Orma::DBError) do
        MacroIdScopedRecord.create(account_id: 1_i64, slug: "welcome")
      end
    end
  end
end
