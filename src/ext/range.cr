require "../orma/to_sql"

# :nodoc:
struct Range(B, E)
  include Orma::ToSql

  def to_sql_value(io : IO)
    raise "Range values require a column for SQL serialization"
  end

  def to_sql_where_condition(query)
    range_begin = self.begin
    range_end = self.end

    if range_begin.nil?
      query << (exclusive? ? "<" : "<=")
      query.add_parameter(range_end.to_db_param)
    elsif range_end.nil?
      query << ">="
      query.add_parameter(range_begin.to_db_param)
    elsif exclusive?
      query << ">="
      query.add_parameter(range_begin.to_db_param)
      query << " AND "
      query.add_where_condition_name
      query << "<"
      query.add_parameter(range_end.to_db_param)
    else
      query << " BETWEEN "
      query.add_parameter(range_begin.to_db_param)
      query << " AND "
      query.add_parameter(range_end.to_db_param)
    end
  end
end
