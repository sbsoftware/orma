require "../orma/to_sql"

# :nodoc:
struct Nil
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "NULL"
  end

  def to_sql_where_condition
    Orma::WhereCondition.sql(" IS ", "NULL")
  end
end
