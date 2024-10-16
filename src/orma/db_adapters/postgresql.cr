require "./base"

class Orma::DbAdapters::Postgresql < Orma::DbAdapters::Base
  def db_type_for(klass)
    case klass
    in Int64.class then "BIGSERIAL"
    in Int32.class then "SERIAL"
    in String.class then "VARCHAR"
    in Bool.class then "BOOLEAN"
    in Time.class then "TIMESTAMP"
    in Slice(UInt8).class then "BLOB"
    end
  end

  def primary_key_column_statement
    "PRIMARY KEY"
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
end
