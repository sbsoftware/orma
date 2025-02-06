require "./spec_helper"
require "sqlite3"

module Orma::BlobColumnSpec
  class Model < Orma::Record
    id_column id : Int64
    column data : Bytes

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "Model" do
    before_all do
      Model.continuous_migration!
    end

    after_all do
      File.delete("./test.db")
    end

    it "should be able to save and load slices of bytes" do
      model = Model.create(data: "Test".to_slice)

      model2 = Model.find(1)
      model2.data.should eq("Test".to_slice)
    end
  end
end
