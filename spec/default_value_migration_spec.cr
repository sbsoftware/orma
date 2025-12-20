require "sqlite3"
require "./spec_helper"

module Orma::DefaultValueMigrationSpec
  class Model < TestRecord
    id_column id : Int64
    column name : String
    column admin : Bool = false
  end

  class MultiModel < TestRecord
    id_column id : Int64
    column name : String
    column admin : Bool = false
    column active : Bool = true
  end

  class RollbackModel < TestRecord
    id_column id : Int64
    column name : String
    column admin : Bool = false
  end

  describe "Model.continuous_migration!" do
    after_each do
      Model.db.exec("DROP TABLE IF EXISTS #{Model.table_name}")
      Model.db.close
    end

    it "backfills NULLs to the default and makes the column NOT NULL" do
      Model.db.exec("DROP TABLE IF EXISTS #{Model.table_name}")
      Model.db.exec("CREATE TABLE #{Model.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, admin BOOLEAN)")
      Model.db.exec("INSERT INTO #{Model.table_name}(name, admin) VALUES ('Alice', NULL)")

      Model.continuous_migration!

      record = Model.find(1_i64)
      record.admin.should be_false

      Model.db.query("PRAGMA table_info(#{Model.table_name})") do |res|
        res.each do
          info = Orma::DbAdapters::Sqlite3::ColumnInfo.new(res)
          if info.name == "admin"
            info.notnull.should be_true
          end
        end
      end
    end

    it "keeps existing non-NULL values untouched while backfilling NULLs" do
      Model.db.exec("DROP TABLE IF EXISTS #{Model.table_name}")
      Model.db.exec("CREATE TABLE #{Model.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, admin BOOLEAN)")
      Model.db.exec("INSERT INTO #{Model.table_name}(name, admin) VALUES ('Alice', 1), ('Bob', NULL)")

      Model.continuous_migration!

      Model.find(1_i64).admin.should be_true
      Model.find(2_i64).admin.should be_false
    end

    it "is idempotent" do
      Model.db.exec("DROP TABLE IF EXISTS #{Model.table_name}")
      Model.db.exec("CREATE TABLE #{Model.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, admin BOOLEAN)")
      Model.db.exec("INSERT INTO #{Model.table_name}(name, admin) VALUES ('Alice', NULL)")

      2.times { Model.continuous_migration! }

      Model.find(1_i64).admin.should be_false
      Model.db.query("PRAGMA table_info(#{Model.table_name})") do |res|
        res.each do
          info = Orma::DbAdapters::Sqlite3::ColumnInfo.new(res)
          if info.name == "admin"
            info.notnull.should be_true
          end
        end
      end
    end
  end

  describe "multiple defaulted columns" do
    after_each do
      MultiModel.db.close
    end

    it "backfills and enforces NOT NULL for each defaulted non-nilable column" do
      MultiModel.db.exec("DROP TABLE IF EXISTS #{MultiModel.table_name}")
      MultiModel.db.exec("CREATE TABLE #{MultiModel.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, admin BOOLEAN, active BOOLEAN)")
      MultiModel.db.exec("INSERT INTO #{MultiModel.table_name}(name, admin, active) VALUES ('Alice', NULL, NULL)")

      MultiModel.continuous_migration!

      rec = MultiModel.find(1_i64)
      rec.admin.should be_false
      rec.active.should be_true

      notnulls = {} of String => Bool
      MultiModel.db.query("PRAGMA table_info(#{MultiModel.table_name})") do |res|
        res.each do
          info = Orma::DbAdapters::Sqlite3::ColumnInfo.new(res)
          notnulls[info.name] = info.notnull
        end
      end

      notnulls["admin"].should be_true
      notnulls["active"].should be_true
    end
  end

  describe "rollback on failure" do
    after_each do
      RollbackModel.db.close
    end

    it "rolls back when the scratch table name already exists" do
      RollbackModel.db.exec("DROP TABLE IF EXISTS #{RollbackModel.table_name}")
      RollbackModel.db.exec("DROP TABLE IF EXISTS #{RollbackModel.table_name}__orma_old")
      RollbackModel.db.exec("CREATE TABLE #{RollbackModel.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, admin BOOLEAN)")
      RollbackModel.db.exec("CREATE TABLE #{RollbackModel.table_name}__orma_old(dummy TEXT)")
      RollbackModel.db.exec("INSERT INTO #{RollbackModel.table_name}(name, admin) VALUES ('Alice', NULL)")

      expect_raises(Exception) do
        RollbackModel.continuous_migration!
      end

      # Column should remain nullable and row should still be backfilled (no constraint applied)
      RollbackModel.db.query("PRAGMA table_info(#{RollbackModel.table_name})") do |res|
        res.each do
          info = Orma::DbAdapters::Sqlite3::ColumnInfo.new(res)
          if info.name == "admin"
            info.notnull.should be_false
          end
        end
      end

      RollbackModel.find(1_i64).admin.should be_false
    end
  end
end
