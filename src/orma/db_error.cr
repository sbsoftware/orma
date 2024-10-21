module Orma
  class DBError < Exception
    getter parent_error : Exception
    getter sql_query : String

    def initialize(@parent_error, @sql_query)
      @message = "#{parent_error.class.name}: #{parent_error.message}\n\nSQL Query: #{sql_query}"
    end
  end
end
