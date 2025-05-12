module Orma
  class Attribute(T)
    getter model : Orma::Record.class
    getter name : Symbol
    property value : T

    # :nodoc:
    forward_missing_to value

    def initialize(@model, @name, value : Attribute(T))
      @value = value.value
    end

    def initialize(@model, @name, @value); end

    def value=(new_val : Attribute(T))
      self.value = new_val.value
    end

    def ==(other : self)
      value == other.value
    end

    def ==(other : T)
      value == other
    end

    def >(other : self)
      value > other.value
    end

    def >(other : T)
      value > other
    end

    def >=(other : self)
      value >= other.value
    end

    def >=(other : T)
      value >= other
    end

    def <(other : self)
      value < other.value
    end

    def <(other : T)
      value < other
    end

    def <=(other : self)
      value <= other.value
    end

    def <=(other : T)
      value <= other
    end

    def to_s(io)
      io << value
    end
  end
end
