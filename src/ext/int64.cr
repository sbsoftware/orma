require "../orma/to_sql"

# :nodoc:
struct Int64
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << self
  end

  def self.from_http_param(str)
    new(str)
  end
end
