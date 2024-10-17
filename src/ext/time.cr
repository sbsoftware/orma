require "../orma/to_sql"

# :nodoc:
struct Time
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "'"
    io << self
    io << "'"
  end

  def self.from_http_param(str)
    parse_rfc3339(str)
  end
end
