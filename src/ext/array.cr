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

  def to_sql_where_condition(io : IO, db_adapter, args, name)
    io << name
    sql_eq_operator(io)
    io << "("
    each_with_index do |item, index|
      io << "," unless index == 0
      db_adapter.add_parameter_placeholder(io, args, item.to_db_param)
    end
    io << ")"
  end
end
