require "../orma/to_sql"

# :nodoc:
class Array(T)
  include Orma::ToSql

  private struct PreparedParamPlaceholder
    include Orma::ToSql

    def to_sql_value(io : IO)
      io << "?"
    end
  end

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

  def to_prepared_where_condition(io : IO, args : Array(DB::Any))
    sql_eq_operator(io)

    Array(PreparedParamPlaceholder).new(size) { PreparedParamPlaceholder.new }.to_sql_value(io)
    each { |item| args << item.to_db_param }
  end
end
