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

  def to_sql_where_condition(io : IO, _db_adapter, _args, name)
    io << name
    sql_eq_operator(io)
    to_sql_value(io)
  end
end
