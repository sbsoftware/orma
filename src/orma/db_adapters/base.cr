require "../db_adapters"

abstract class Orma::DbAdapters::Base
  abstract def db_type_for(klass)
  abstract def primary_key_db_type_for(klass)
  abstract def primary_key_column_statement
  abstract def query_index_names
  abstract def sync_column_constraints(table_name : String, constraints : Hash(String, Orma::DbAdapters::DesiredColumnConstraints))

  getter db : DB::Database | DB::Connection

  def initialize(@db); end

  def self.add_default_connection_string_options(connection_string : String) : String
    connection_string
  end

  def parameter_placeholder(args : Array(DB::Any))
    "?"
  end

  def add_parameter_placeholder(io : IO, args : Array(DB::Any), value : DB::Any)
    io << parameter_placeholder(args)
    args << value
  end

  def add_lock_clause(io : IO)
  end

  def insert_and_return_id(query : String, args : Array(DB::Any), id_column : String) : Int64
    db.exec(query, args: args).last_insert_id
  end

  def query_column_names(table_name : String) : Array(String)
    names = [] of String
    db.query("SELECT * FROM #{table_name} LIMIT 1") do |res|
      names = res.column_names
    end
    names
  end
end
