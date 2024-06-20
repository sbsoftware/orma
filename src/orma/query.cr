class Orma::Query(T)
  getter where_clause : String?
  @collection : Array(T)?

  delegate :db, :table_name, to: T

  def initialize(@where_clause = nil); end

  def each
    collection.each do |item|
      yield item
    end
  end

  def map
    collection.map do |item|
      yield item
    end
  end

  def find_each(*, batch_size = 1000)
    if (total_count = count) > batch_size
      ((total_count // batch_size) + 1).times do |i|
        load_batch(i, batch_size).each do |item|
          yield item
        end
      end
    else
      each do |item|
        yield item
      end
    end
  end

  private def load_batch(batch_no, batch_size)
    db.query("#{find_all_query} OFFSET #{batch_no * batch_size} LIMIT #{batch_size}") do |res|
      T.load_many_from_result(res)
    end
  end

  def count
    db.query(count_query) do |res|
      res.read(Int64)
    end
  end

  def to_a
    collection
  end

  private def count_query
    build_query("COUNT(*)")
  end

  private def find_all_query
    build_query("*")
  end

  private def build_query(select_clause)
    String.build do |str|
      str << "SELECT #{select_clause} FROM #{table_name}"
      if where_clause
        str << " WHERE "
        str << where_clause
      end
    end
  end

  private def collection
    @collection ||= db.query(find_all_query) do |res|
      T.load_many_from_result(res)
    end
  end
end
