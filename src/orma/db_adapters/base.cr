require "../../../spec/fake_db"

# :nodoc:
abstract class Orma::DbAdapters::Base
  getter db : DB::Database | FakeDB.class

  def initialize(@db); end

  abstract def db_type_for(klass)
  abstract def primary_key_column_statement
  abstract def query_index_names
end
