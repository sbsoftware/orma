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

  def to_prepared_where_condition(io : IO, args : Array(DB::Any), db_adapter)
    sql_eq_operator(io)

    io << "("
    join(io, ",") do |item, io|
      db_adapter.add_parameter_placeholder(io, args, item.to_db_param)
    end
    io << ")"
  end
end
