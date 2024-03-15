module Orma
  module ToSql
    def to_sql_where_condition(io : IO)
      sql_eq_operator(io)
      to_sql_value(io)
    end

    def to_sql_update_value(io : IO)
      io << "="
      to_sql_value(io)
    end

    def to_sql_insert_value(io : IO)
      to_sql_value(io)
    end

    abstract def to_sql_value(io : IO)

    def sql_eq_operator(io : IO)
      io << "="
    end
  end
end
