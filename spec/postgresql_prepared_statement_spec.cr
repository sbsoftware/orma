require "./spec_helper"

module Orma::PostgresqlPreparedStatementSpec
  class Record < TestRecord
    id_column id : Int64
    column name : String
    column age : Int32

    def self.db_adapter
      Orma::DbAdapters::Postgresql.new(db)
    end
  end

  describe "PostgreSQL prepared statements" do
    describe "via .find" do
      it "uses numbered placeholders" do
        err = expect_raises(Orma::DBError) do
          Record.find(2)
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE id=$1 LIMIT 1")
      end
    end

    describe "via #reload" do
      it "uses numbered placeholders" do
        err = expect_raises(Orma::DBError) do
          Record.new(id: 1_i64, name: "Foo", age: 1).reload
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE id=$1 LIMIT 1")
      end
    end

    describe "via #to_a" do
      it "uses numbered placeholders for scalar conditions" do
        err = expect_raises(Orma::DBError) do
          Record.where(name: "test").to_a
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE name=$1")
      end

      it "uses numbered placeholders for list conditions" do
        err = expect_raises(Orma::DBError) do
          Record.where(id: [1_i64, 2_i64]).to_a
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE id IN ($1,$2)")
      end

      it "continues numbering through limits" do
        err = expect_raises(Orma::DBError) do
          Record.where(name: "test").limit(5).to_a
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE name=$1 LIMIT $2")
      end
    end

    describe "via #count" do
      it "uses numbered placeholders" do
        err = expect_raises(Orma::DBError) do
          Record.where(name: "test", age: 1).count
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: SELECT COUNT(*) FROM orma_postgresql_prepared_statement_spec_records WHERE name=$1 AND age=$2")
      end
    end

    describe "via .create" do
      it "uses numbered placeholders" do
        err = expect_raises(Orma::DBError) do
          Record.create(name: "Blah", age: 1)
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: INSERT INTO orma_postgresql_prepared_statement_spec_records(name, age) VALUES ($1, $2)")
      end
    end

    describe "via #save on an existing record" do
      it "uses numbered placeholders" do
        rec = Record.new(id: 1_i64, name: "Foo", age: 1)

        err = expect_raises(Orma::DBError) do
          rec.name = "Bar"
          rec.save
        end

        err.message.should eq("SQLite3::Exception: no such table: orma_postgresql_prepared_statement_spec_records\n\nSQL Query: UPDATE orma_postgresql_prepared_statement_spec_records SET name=$1, age=$2 WHERE id=$3")
      end
    end
  end
end
