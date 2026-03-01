require "spec"
require "../src/orma"
require "sqlite3"

TEST_DB_CONNECTION_STRING = "sqlite3:%3Amemory%3A?max_pool_size=1&prepared_statements_cache=false"

Orma.db_connection_string = TEST_DB_CONNECTION_STRING

module Orma
  def self.reset_db!
    @@db.try &.close
  rescue
  ensure
    @@db = nil
    @@db_adapter = nil
  end
end

abstract class TestRecord < Orma::Record; end
