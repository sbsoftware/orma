require "spec"
require "../src/orma"
require "./fake_db"
require "sqlite3"

abstract class TestRecord < Orma::Record
  DB_PATH = "./test.db"

  id_column id : Int64

  def self.db_connection_string
    "sqlite3://#{DB_PATH}"
  end

  macro inherited
    self.continuous_migration!
  end
end

if File.exists?(TestRecord::DB_PATH)
  File.delete(TestRecord::DB_PATH)
end
