require "../orma/to_sql"

struct Bool
  include Orma::ToSql

  def to_sql_value(io : IO)
    if self
      io << "TRUE"
    else
      io << "FALSE"
    end
  end
end
