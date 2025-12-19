require "./spec_helper"
require "sqlite3"

module Orma::DeleteRemovedDeprecatedColumnsSpec
  class Model < TestRecord
    id_column id : Int32
    column a : String
    # deprecated_column b : Int32
    column d : String
  end

  describe "Model.delete_removed_deprecated_columns!" do
    after_all do
      Model.db.close
    end

    it "should remove deprecated columns that have no corresponding instance var" do
      Model.db.exec "CREATE TABLE #{Model.table_name} (id INTEGER PRIMARY KEY AUTOINCREMENT, a STRING, _b_deprecated INTEGER, c INTEGER, d STRING)"

      Model.query_column_names.should eq(["id", "a", "_b_deprecated", "c", "d"])

      Model.delete_removed_deprecated_columns!

      # Non-deprecated columns should not be touched even if they have no corresponding instance var
      Model.query_column_names.should eq(["id", "a", "c", "d"])

      # calling any continuous migration method should make no further column changes
      Model.continuous_migration!

      Model.query_column_names.should eq(["id", "a", "c", "d"])
    end
  end
end
