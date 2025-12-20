require "../db_adapters"

abstract class Orma::DbAdapters::Base
  abstract def db_type_for(klass)
  abstract def primary_key_column_statement
  abstract def query_index_names
  abstract def sync_column_constraints(table_name : String, constraints : Hash(String, Orma::DbAdapters::DesiredColumnConstraints))

  getter db : DB::Database | DB::Connection

  def initialize(@db); end

  def query_column_names(table_name : String) : Array(String)
    names = [] of String
    db.query("SELECT * FROM #{table_name} LIMIT 1") do |res|
      names = res.column_names
    end
    names
  end
end
