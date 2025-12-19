require "spec"
require "../src/orma"
require "sqlite3"

TEST_DB_CONNECTION_STRING = "sqlite3:%3Amemory%3A?max_pool_size=1"

abstract class TestRecord < Orma::Record
  def self.db_connection_string
    ::TEST_DB_CONNECTION_STRING
  end
end
