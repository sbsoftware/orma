require "../../../spec/fake_db"

# :nodoc:
abstract class Orma::DbAdapters::Base
  getter db : DB::Database | DB::Connection | FakeDB.class

  def initialize(@db); end

  abstract def db_type_for(klass)
  abstract def primary_key_column_statement
  abstract def query_index_names
  abstract def enforce_not_null_with_default? : Bool
  abstract def enforce_not_null_with_default(table_name : String, column_name : String, default_sql : String)
end
