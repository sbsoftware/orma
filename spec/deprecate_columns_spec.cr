require "./spec_helper"
require "sqlite3"

module Orma::DeprecateColumnsSpec
  class MyRecord < Orma::Record
    id_column id : Int32?
    deprecated_column name : String?

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "MyRecord.deprecate_columns!" do
    after_each do
      File.delete("./test.db")
    end

    it "should rename the name column once" do
      MyRecord.ensure_table_exists!
      col_names = MyRecord.db.query("SELECT * FROM #{MyRecord.table_name} LIMIT 1").column_names
      col_names.should eq(["id", "name"])

      MyRecord.deprecate_columns!
      col_names = MyRecord.db.query("SELECT * FROM #{MyRecord.table_name} LIMIT 1").column_names
      col_names.should eq(["id", "_name_deprecated"])

      # calling any continuous migration method should make no further column name changes
      MyRecord.continuous_migration!
      col_names = MyRecord.db.query("SELECT * FROM #{MyRecord.table_name} LIMIT 1").column_names
      col_names.should eq(["id", "_name_deprecated"])
    end

    it "should still query the value correctly after renaming the column" do
      MyRecord.ensure_table_exists!

      # Cannot use record instance as it already has no setter method anymore
      MyRecord.db.exec "INSERT INTO #{MyRecord.table_name}(id, name)VALUES(1, 'Test')"

      MyRecord.deprecate_columns!

      my_record = MyRecord.find(1)
      my_record.name.value.should eq("Test")
    end
  end
end
