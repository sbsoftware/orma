require "../orma/to_sql"

# :nodoc:
struct Range(B, E)
  include Orma::ToSql

  def to_sql_value(io : IO)
    raise "Range values require a column for SQL serialization"
  end

  def to_sql_where_condition
    range_begin = self.begin
    range_end = self.end

    if range_begin.nil?
      Orma::WhereCondition.parameter(exclusive? ? "<" : "<=", range_end.not_nil!.to_db_param)
    elsif range_end.nil?
      Orma::WhereCondition.parameter(">=", range_begin.to_db_param)
    elsif exclusive?
      Orma::WhereCondition.new([Orma::WhereCondition::Predicate.parameter(">=", range_begin.to_db_param), Orma::WhereCondition::Predicate.parameter("<", range_end.to_db_param)])
    else
      Orma::WhereCondition.new([Orma::WhereCondition::Predicate.new(" BETWEEN ", [Orma::WhereCondition::Value.parameter(range_begin.to_db_param), Orma::WhereCondition::Value.parameter(range_end.to_db_param)], " AND ")])
    end
  end
end
