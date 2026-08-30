require "db"

module Orma
  # :nodoc:
  class WhereCondition
    # :nodoc:
    class Value
      getter sql : String?
      getter parameter : DB::Any?

      private def initialize(@sql : String?, @parameter : DB::Any?, @parameterized : Bool)
      end

      def self.sql(sql : String)
        new(sql, nil, false)
      end

      def self.parameter(parameter : DB::Any)
        new(nil, parameter, true)
      end

      def parameterized?
        @parameterized
      end
    end

    # :nodoc:
    record Predicate, operator : String, values : Array(Value), value_separator : String = ",", wrap_values : Bool = false do
      def self.sql(operator : String, sql : String)
        new(operator, [Value.sql(sql)])
      end

      def self.parameter(operator : String, parameter : DB::Any)
        new(operator, [Value.parameter(parameter)])
      end
    end

    getter predicates : Array(Predicate)
    getter combinator : String

    def initialize(@predicates : Array(Predicate), @combinator = " AND ")
    end

    def self.sql(operator : String, sql : String)
      new([Predicate.sql(operator, sql)])
    end

    def self.parameter(operator : String, parameter : DB::Any)
      new([Predicate.parameter(operator, parameter)])
    end
  end
end
