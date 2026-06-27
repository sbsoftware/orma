require "../orma/to_sql"

# :nodoc:
class Array(T)
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "("
    join(io, ",") do |item, io|
      item.to_sql_value(io)
    end
    io << ")"
  end

  def sql_eq_operator(io)
    io << " IN "
  end

  def to_sql_where_condition(io : IO)
    sql_eq_operator(io)
    to_sql_value(io)
  end

  def to_sql_where_condition(query)
    sql_eq_operator(query)
    query << "("
    each_with_index do |item, index|
      query << "," unless index == 0
      query.add_parameter(item.to_db_param)
    end
    query << ")"
  end
end
