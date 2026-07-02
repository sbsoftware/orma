require "./spec_helper"
require "sqlite3"

module Orma::ResultSetDeserializationSpec
  class Model < TestRecord
    id_column id : Int64
    column name : String
  end

  describe "result set deserialization" do
    before_each do
      Model.db.exec("DROP TABLE IF EXISTS #{Model.table_name}")
      Model.db.exec("CREATE TABLE #{Model.table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, removed_column TEXT, name TEXT)")
      Model.db.exec("INSERT INTO #{Model.table_name}(removed_column, name) VALUES ('Unexpected', 'Expected')")
    end

    after_each do
      Orma.reset_db!
    end

    it "ignores unexpected columns without misaligning following attributes" do
      Model.find(1_i64).name.should eq("Expected")
    end

    it "ignores unexpected columns while reloading an existing instance" do
      model = Model.new(id: 1_i64, name: "Stale")

      model.reload.name.should eq("Expected")
    end
  end
end
