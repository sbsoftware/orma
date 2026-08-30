require "../spec_helper"

describe Orma::DbAdapters::Sqlite3 do
  db = uninitialized DB::Database
  adapter = Orma::DbAdapters::Sqlite3.new(db)

  it "does not add a lock clause because SQLite locks through the transaction" do
    String.build { |io| adapter.add_lock_clause(io) }.should eq("")
  end

  it "generates unique index SQL for multiple columns" do
    adapter.create_unique_index_sql("records", "idx_records_slug_account_id", ["slug", "account_id"]).should eq("CREATE UNIQUE INDEX idx_records_slug_account_id ON records (slug, account_id)")
  end

  describe ".add_default_connection_string_options" do
    it "adds default options missing from the connection string" do
      connection_string = Orma::DbAdapters::Sqlite3.add_default_connection_string_options("sqlite3:%3Amemory%3A?max_pool_size=1")

      URI.parse(connection_string).query_params.should eq(URI::Params.parse("max_pool_size=1&journal_mode=wal&synchronous=normal&busy_timeout=5000"))
    end

    it "preserves configured options" do
      connection_string = Orma::DbAdapters::Sqlite3.add_default_connection_string_options("sqlite3:%3Amemory%3A?journal_mode=delete&synchronous=full&busy_timeout=100")

      URI.parse(connection_string).query_params.should eq(URI::Params.parse("journal_mode=delete&synchronous=full&busy_timeout=100"))
    end
  end
end

describe Orma do
  describe ".db_connection_string" do
    after_each do
      Orma.reset_db!
      Orma.db_connection_string = TEST_DB_CONNECTION_STRING
    end

    it "returns the raw configured connection string" do
      Orma.reset_db!
      Orma.db_connection_string = "sqlite3:%3Amemory%3A?max_pool_size=1"

      Orma.db_connection_string.should eq("sqlite3:%3Amemory%3A?max_pool_size=1")
    end
  end
end
