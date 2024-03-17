require "./base"

class Orma::DbAdapters::Sqlite3 < Orma::DbAdapters::Base
  def db_type_for(klass)
    case klass
      in Int64.class then "INTEGER"
      in Int32.class then "INTEGER"
      in String.class then "TEXT"
      in Bool.class then "INTEGER"
      in Time.class then "INTEGER"
    end
  end

  def primary_key_column_statement
    "PRIMARY KEY AUTOINCREMENT"
  end
end
