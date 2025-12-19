require "../../../spec/fake_db"

# :nodoc:
abstract class Orma::DbAdapters::Base
  abstract def db_type_for(klass)
  abstract def primary_key_column_statement
  abstract def query_index_names
  abstract def enforce_not_null_with_default? : Bool
  abstract def enforce_not_null_with_default(table_name : String, column_name : String, default_sql : String)

  getter db : DB::Database | DB::Connection | FakeDB.class

  def initialize(@db); end

  def query_column_names(table_name : String) : Array(String)
    case db
    when DB::Database, DB::Connection
      session = db.as(DB::Database | DB::Connection)
      names = [] of String
      session.query("SELECT * FROM #{table_name} LIMIT 1") do |res|
        names = res.column_names
      end
      names
    when FakeDB.class
      raise "FakeDB does not support schema introspection"
    else
      raise "Unsupported DB connection type: #{typeof(db)}"
    end
  end
end
