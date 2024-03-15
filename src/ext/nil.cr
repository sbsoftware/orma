require "../orma/to_sql"

struct Nil
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "NULL"
  end

  def sql_eq_operator(io : IO)
    io << " IS "
  end
end
