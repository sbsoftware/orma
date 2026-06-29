require "./base"

# :nodoc:
class Orma::DbAdapters::Postgresql < Orma::DbAdapters::Base
  def db_type_for(klass)
    case klass
    in Int64.class        then "BIGINT"
    in Int32.class        then "INTEGER"
    in String.class       then "VARCHAR"
    in Bool.class         then "BOOLEAN"
    in Time.class         then "TIMESTAMP"
    in Slice(UInt8).class then "BYTEA"
    end
  end

  def primary_key_db_type_for(klass)
    case klass
    when Int64.class then "BIGSERIAL"
    when Int32.class then "SERIAL"
    else
      db_type_for(klass)
    end
  end

  def primary_key_column_statement
    "PRIMARY KEY"
  end

  def parameter_placeholder(args : Array(DB::Any))
    "$#{args.size + 1}"
  end

  def add_lock_clause(io : IO)
    io << " FOR UPDATE"
  end

  def insert_and_return_id(query : String, args : Array(DB::Any), id_column : String) : Int64
    db.query_one("#{query} RETURNING #{id_column}::bigint", args: args) do |res|
      res.read(Int64)
    end
  end

  def query_index_names
    names = [] of String

    db.query("SELECT indexname FROM pg_indexes") do |res|
      res.each do
        res.each_column do |column|
          if column == "indexname"
            names << res.read(String)
          end
        end
      end
    end

    names
  end

  def sync_column_constraints(table_name : String, constraints : Hash(String, Orma::DbAdapters::DesiredColumnConstraints))
    constraints.each do |column_name, desired|
      if desired.default_sql
        db.exec "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET DEFAULT #{desired.default_sql}"
      else
        db.exec "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} DROP DEFAULT"
      end

      case desired.not_null
      when true
        db.exec "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET NOT NULL"
      when false
        db.exec "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} DROP NOT NULL"
      end
    end
  end

  def unique_index_data_violation?(error : Exception) : Bool
    message = error.message
    return false unless message

    message.includes?("could not create unique index") && message.includes?("duplicated")
  end
end
