require "../orma/to_sql"

# :nodoc:
struct Range(B, E)
  include Orma::ToSql

  def to_sql_value(io : IO)
    raise "Range values require a column for SQL serialization"
  end

  def to_sql_where_condition(io : IO, db_adapter, args, name)
    range_begin = self.begin
    range_end = self.end

    if range_begin.nil?
      io << name
      io << (exclusive? ? "<" : "<=")
      db_adapter.add_parameter_placeholder(io, args, range_end.to_db_param)
    elsif range_end.nil?
      io << name
      io << ">="
      db_adapter.add_parameter_placeholder(io, args, range_begin.to_db_param)
    elsif exclusive?
      io << name
      io << ">="
      db_adapter.add_parameter_placeholder(io, args, range_begin.to_db_param)
      io << " AND "
      io << name
      io << "<"
      db_adapter.add_parameter_placeholder(io, args, range_end.to_db_param)
    else
      io << name
      io << " BETWEEN "
      db_adapter.add_parameter_placeholder(io, args, range_begin.to_db_param)
      io << " AND "
      db_adapter.add_parameter_placeholder(io, args, range_end.to_db_param)
    end
  end
end
