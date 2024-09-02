require "../orma/to_sql"

class String
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "'"
    io << self.gsub("'", "''")
    io << "'"
  end

  def self.from_http_param(str)
    str
  end
end
