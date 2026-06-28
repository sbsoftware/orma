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

  def to_sql_where_condition
    Orma::WhereCondition.new([Orma::WhereCondition::Predicate.new(" IN ", map { |item| Orma::WhereCondition::Value.parameter(item.to_db_param) }, ",", true)])
  end
end
