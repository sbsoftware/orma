require "./spec_helper"
require "sqlite3"

module Orma::EnsureColumnsExistSpec
  class MyRecord < Orma::Record
    id_column id : Int32?
    column name : String?
    column foo : Int32?
    # TODO: This column will not be created, which I think is the correct behavior but there should probably be some warning - or even an error?
    deprecated_column bar : String?

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "MyRecord.ensure_columns_exist!" do
    after_each do
      File.delete("./test.db")
    end

    it "should add any missing non-deprecated column" do
      MyRecord.db.exec(<<-SQL)
      CREATE TABLE #{MyRecord.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT)
      SQL

      MyRecord.query_column_names.should eq(["id"])

      MyRecord.ensure_columns_exist!

      MyRecord.query_column_names.should eq(["id", "name", "foo"])
    end
  end
end
