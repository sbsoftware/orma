require "../orma/to_sql"

# :nodoc:
struct Nil
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "NULL"
  end

  def sql_eq_operator(io : IO)
    io << " IS "
  end

  def to_sql_where_condition(query)
    query << " IS NULL"
  end
end
