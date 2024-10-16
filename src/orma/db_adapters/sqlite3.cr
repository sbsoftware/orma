require "./base"

class Orma::DbAdapters::Sqlite3 < Orma::DbAdapters::Base
  def db_type_for(klass)
    case klass
      in Int64.class then "INTEGER"
      in Int32.class then "INTEGER"
      in String.class then "TEXT"
      in Bool.class then "INTEGER"
      in Time.class then "INTEGER"
      in Slice(UInt8).class then "BLOB"
    end
  end

  def primary_key_column_statement
    "PRIMARY KEY AUTOINCREMENT"
  end

  def query_index_names
    names = [] of String

    db.query("SELECT name FROM sqlite_schema WHERE type='index'") do |res|
      res.each do
        res.each_column do |column|
          if column == "name"
            names << res.read(String)
          end
        end
      end
    end

    names
  end
end
