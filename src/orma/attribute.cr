module Orma
  class Attribute(T)
    getter model : Orma::Record.class
    getter name : Symbol
    property value : T

    delegate :to_sql_where_condition, :to_sql_update_value, :to_sql_insert_value, to: value

    def initialize(@model, @name, @value = nil); end

    def value=(new_val : Attribute(T))
      self.value = new_val.value
    end

    def ==(other : self)
      value == other.value
    end

    def ==(other : T)
      value == other
    end

    def to_s(io)
      io << value
    end
  end
end
