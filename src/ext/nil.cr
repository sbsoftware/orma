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

  def to_prepared_where_condition(io : IO, _args : Array(DB::Any))
    sql_eq_operator(io)
    to_sql_value(io)
  end
end
