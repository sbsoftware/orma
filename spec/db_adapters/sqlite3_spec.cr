require "../spec_helper"

describe Orma::DbAdapters::Sqlite3 do
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
