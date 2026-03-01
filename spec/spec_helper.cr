require "spec"
require "../src/orma"
require "sqlite3"

TEST_DB_CONNECTION_STRING = "sqlite3:%3Amemory%3A?max_pool_size=1&prepared_statements_cache=false"

abstract class TestRecord < Orma::Record
  def self.db_connection_string
    ::TEST_DB_CONNECTION_STRING
  end
end

class DB::Database
  # Specs close the shared in-memory DB from many contexts; SQLite may still hold
  # transient statements and raise during teardown-only closes.
  def close
    previous_def
  rescue SQLite3::Exception
  end
end
