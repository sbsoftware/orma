require "sqlite3"
require "./spec_helper"

module Orma::ErrorSpec
  class Record < Orma::Record
    id_column id : Int64
    column name : String

    def self.db_connection_string
      "sqlite3://./test.db"
    end
  end

  describe "when triggering DB driver exceptions" do
    after_all do
      File.delete("./test.db")
    end

    describe "via .find" do
      it "raises an error containing the message and the query triggering it" do
        err = expect_raises(Orma::DBError) do
          Record.find(2)
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_error_spec_records\n\nSQL Query: SELECT * FROM orma_error_spec_records WHERE id=2 LIMIT 1")
      end
    end

    describe "via #to_a" do
      it "raises an error containing the message and the query triggering it" do
        err = expect_raises(Orma::DBError) do
          Record.where({"name" => "test"}).to_a
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_error_spec_records\n\nSQL Query: SELECT * FROM orma_error_spec_records WHERE name='test'")
      end
    end

    describe "via #count" do
      it "raises an error containing the message and the query triggering it" do
        err = expect_raises(Orma::DBError) do
          Record.where({"name" => "test"}).count
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_error_spec_records\n\nSQL Query: SELECT COUNT(*) FROM orma_error_spec_records WHERE name='test'")
      end
    end

    describe "via .create" do
      it "raises an error containing the message and the query triggering it" do
        err = expect_raises(Orma::DBError) do
          Record.create(name: "Blah")
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_error_spec_records\n\nSQL Query: INSERT INTO orma_error_spec_records(name) VALUES ('Blah')")
      end
    end

    describe "via #save on an existing record" do
      it "raises an error containing the message and the query triggering it" do
        rec1 = Record.new(id: 1_i64, name: "Foo")

        err = expect_raises(Orma::DBError) do
          rec1.name = "Bar"
          rec1.save
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_error_spec_records\n\nSQL Query: UPDATE orma_error_spec_records SET name='Bar' WHERE id=1")
      end
    end
  end
end
