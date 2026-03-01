require "sqlite3"
require "./spec_helper"

module Orma::RemoveColumnConstraintsSpec
  class DefaultRemovedModel < TestRecord
    id_column id : Int64
    column name : String
    column admin : Bool
  end

  class NotNullRemovedModel < TestRecord
    id_column id : Int64
    column name : String
    column nickname : String?
  end

  describe "continuous migration" do
    after_each do
      DefaultRemovedModel.db.exec("DROP TABLE IF EXISTS #{DefaultRemovedModel.table_name}")
      NotNullRemovedModel.db.exec("DROP TABLE IF EXISTS #{NotNullRemovedModel.table_name}")
      Orma.reset_db!
    end

    it "removes DB defaults no longer defined in the model" do
      DefaultRemovedModel.db.exec("DROP TABLE IF EXISTS #{DefaultRemovedModel.table_name}")
      DefaultRemovedModel.db.exec("CREATE TABLE #{DefaultRemovedModel.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, admin BOOLEAN NOT NULL DEFAULT 1)")

      DefaultRemovedModel.continuous_migration!

      info_by_name = {} of String => Orma::DbAdapters::Sqlite3::ColumnInfo
      DefaultRemovedModel.db.query("PRAGMA table_info(#{DefaultRemovedModel.table_name})") do |res|
        res.each do
          info = Orma::DbAdapters::Sqlite3::ColumnInfo.new(res)
          info_by_name[info.name] = info
        end
      end

      info_by_name["admin"].dflt_value.should be_nil
      info_by_name["admin"].notnull.should be_true
    end

    it "keeps DB NOT NULL when the model has no opinion (not_null=nil)" do
      DefaultRemovedModel.db.exec("DROP TABLE IF EXISTS #{DefaultRemovedModel.table_name}")
      DefaultRemovedModel.db.exec("CREATE TABLE #{DefaultRemovedModel.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, admin BOOLEAN NOT NULL DEFAULT 1)")

      DefaultRemovedModel.continuous_migration!

      info_by_name = {} of String => Orma::DbAdapters::Sqlite3::ColumnInfo
      DefaultRemovedModel.db.query("PRAGMA table_info(#{DefaultRemovedModel.table_name})") do |res|
        res.each do
          info = Orma::DbAdapters::Sqlite3::ColumnInfo.new(res)
          info_by_name[info.name] = info
        end
      end

      info_by_name["name"].notnull.should be_true
      info_by_name["admin"].dflt_value.should be_nil
      info_by_name["admin"].notnull.should be_true
    end

    it "removes DB NOT NULL when the model column is nilable" do
      NotNullRemovedModel.db.exec("DROP TABLE IF EXISTS #{NotNullRemovedModel.table_name}")
      NotNullRemovedModel.db.exec("CREATE TABLE #{NotNullRemovedModel.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, nickname TEXT NOT NULL)")

      NotNullRemovedModel.continuous_migration!

      info_by_name = {} of String => Orma::DbAdapters::Sqlite3::ColumnInfo
      NotNullRemovedModel.db.query("PRAGMA table_info(#{NotNullRemovedModel.table_name})") do |res|
        res.each do
          info = Orma::DbAdapters::Sqlite3::ColumnInfo.new(res)
          info_by_name[info.name] = info
        end
      end

      info_by_name["nickname"].notnull.should be_false
    end
  end
end
