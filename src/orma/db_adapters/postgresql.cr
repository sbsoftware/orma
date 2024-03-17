require "./base"

class Orma::DbAdapters::Postgresql < Orma::DbAdapters::Base
  def db_type_for(klass)
    case klass
    in Int64.class then "BIGSERIAL"
    in Int32.class then "SERIAL"
    in String.class then "VARCHAR"
    in Bool.class then "BOOLEAN"
    in Time.class then "TIMESTAMP"
    end
  end

  def primary_key_column_statement
    "PRIMARY KEY"
  end
end
