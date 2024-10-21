class Orma::Query(T)
  include Indexable(T)

  # :nodoc:
  getter where_clause : String?
  @collection : Array(T)?

  # :nodoc:
  delegate :db, :table_name, to: T

  delegate :size, :unsafe_fetch, to: collection

  def initialize(@where_clause = nil); end

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
    sql = "#{find_all_query} LIMIT #{batch_size} OFFSET #{batch_no * batch_size}"
    begin
      db.query(sql) do |res|
        T.load_many_from_result(res)
      end
    rescue err
      raise DBError.new(err, sql)
    end
  end

  def count
    sql = count_query
    begin
      db.scalar(sql).as(Int64)
    rescue err
      raise DBError.new(err, sql)
    end
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
    @collection ||= begin
                      sql = find_all_query
                      begin
                        db.query(sql) do |res|
                          T.load_many_from_result(res)
                        end
                      rescue err
                        raise DBError.new(err, sql)
                      end
                    end
  end
end
