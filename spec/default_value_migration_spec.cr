require "sqlite3"
require "./spec_helper"

module Orma::DefaultValueMigrationSpec
  class ::Orma::DbAdapters::Sqlite3
    # enable NOT NULL enforcement for this spec run
    def enforce_not_null_with_default? : Bool
      true
    end
  end

  class Model < Orma::Record
    id_column id : Int64
    column name : String
    column admin : Bool = false

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  class MultiModel < Orma::Record
    id_column id : Int64
    column name : String
    column admin : Bool = false
    column active : Bool = true

    def self.db_connection_string
      "sqlite3://./test_multi.db"
    end
  end

  class RollbackModel < Orma::Record
    id_column id : Int64
    column name : String
    column admin : Bool = false

    def self.db_connection_string
      "sqlite3://./test_rb.db"
    end
  end

  describe "Model.continuous_migration!" do
    after_each do
      Model.db.exec("DROP TABLE IF EXISTS #{Model.table_name}")
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
      File.delete("./test_multi.db") if File.exists?("./test_multi.db")
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
      File.delete("./test_rb.db") if File.exists?("./test_rb.db")
    end

    it "rolls back when temp column already exists" do
      RollbackModel.db.exec("DROP TABLE IF EXISTS #{RollbackModel.table_name}")
      RollbackModel.db.exec("CREATE TABLE #{RollbackModel.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, admin BOOLEAN, admin__orma_tmp BOOLEAN)")
      RollbackModel.db.exec("INSERT INTO #{RollbackModel.table_name}(name, admin, admin__orma_tmp) VALUES ('Alice', NULL, 1)")

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
