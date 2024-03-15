require "../orma/to_sql"

struct Int64
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << self
  end
end
