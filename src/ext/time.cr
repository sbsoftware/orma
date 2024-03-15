require "../orma/to_sql"

struct Time
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "'"
    io << self
    io << "'"
  end
end
