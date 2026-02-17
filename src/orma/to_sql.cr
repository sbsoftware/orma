require "db"

module Orma
  # :nodoc:
  module ToSql
    def to_prepared_where_condition(io : IO, args : Array(DB::Any))
      sql_eq_operator(io)
      io << "?"
      args << to_db_param
    end

    def to_db_param : DB::Any
      self.as(DB::Any)
    end

    def to_sql_where_condition(io : IO)
      sql_eq_operator(io)
      to_sql_value(io)
    end

    def to_sql_where_condition : String
      String.build do |io|
        to_sql_where_condition(io)
      end
    end

    def to_sql_update_value(io : IO)
      io << "="
      to_sql_value(io)
    end

    def to_sql_update_value : String
      String.build do |io|
        to_sql_update_value(io)
      end
    end

    def to_sql_insert_value(io : IO)
      to_sql_value(io)
    end

    def to_sql_insert_value : String
      String.build do |io|
        to_sql_insert_value(io)
      end
    end

    abstract def to_sql_value(io : IO)

    def to_sql_value : String
      String.build do |io|
        to_sql_value(io)
      end
    end

    def sql_eq_operator(io : IO)
      io << "="
    end

    def sql_eq_operator : String
      String.build do |io|
        sql_eq_operator(io)
      end
    end
  end
end
