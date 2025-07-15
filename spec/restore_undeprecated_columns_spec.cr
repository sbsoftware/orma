require "./spec_helper"
require "sqlite3"

module Orma::RestoreUndeprecatedColumnsSpec
  class Model < Orma::Record
    id_column id : Int32
    column name : String

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "Model.restore_undeprecated_columns!" do
    after_each do
      File.delete("./test.db")
    end

    it "should rename the column once" do
      Model.db.exec "CREATE TABLE #{Model.table_name} (id INTEGER PRIMARY KEY AUTOINCREMENT, _name_deprecated STRING);"

      Model.query_column_names.should eq(["id", "_name_deprecated"])

      Model.restore_undeprecated_columns!

      Model.query_column_names.should eq(["id", "name"])

      # calling any continuous migration method should make no further column name changes
      Model.continuous_migration!

      Model.query_column_names.should eq(["id", "name"])
    end
  end
end
