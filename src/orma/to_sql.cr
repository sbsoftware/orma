require "db"
require "./where_condition"

module Orma
  # :nodoc:
  module ToSql
    def to_db_param : DB::Any
      self.as(DB::Any)
    end

    def to_sql_where_condition
      WhereCondition.parameter("=", to_db_param)
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
  end
end
