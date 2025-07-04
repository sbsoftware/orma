abstract class Orma::Query
  annotation WhereCondition; end

  abstract def load_many_from_result(res)

  delegate :size, :each, :each_with_index, :map, :first, :first?, :last, :last?, to: collection

  record Condition(T), name : String, value : T do
    def to_s(io : IO)
      io << name
      value.to_sql_where_condition(io)
    end
  end

  def initialize(**conditions : **K) forall K
    {% for key in K.keys.map(&.id) %}
      {% if ivar = @type.instance_vars.find { |iv| iv.annotation(WhereCondition) && iv.name.id == "#{key}_condition".id } %}
        {% type = ivar.type.union_types.find { |t| t != Nil }.type_vars.first %}
        @{{key}}_condition = Condition({{type}}?).new({{key.stringify}}, conditions[{{key.symbolize}}])
      {% else %}
        {% raise "No column: #{key}" %}
      {% end %}
    {% end %}
  end

  def initialize(conditions : Hash(String, K)) forall K
    conditions.each do |key, value|
      {% begin %}
        case "#{key}_condition"
        {% for ivar in @type.instance_vars.select { |iv| iv.annotation(WhereCondition) } %}
        {% type = ivar.type.union_types.find { |t| t != Nil }.type_vars.first %}
        when {{ivar.name.stringify}}
          if value.is_a?({{type}})
            @{{ivar.name.id}} = Condition({{type}}?).new(key, value)
          else
            raise "#{key} must be of type {{type}}, not #{typeof(value)}"
          end
        {% end %}
        else
          raise "Not a column: #{key}"
        end
      {% end %}
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

  def count
    sql = count_query
    begin
      db.scalar(sql).as(Int64)
    rescue err
      raise DBError.new(err, sql)
    end
  end

  def to_a
    collection.dup.to_a
  end

  private def where_clause
    first = true

    String.build do |str|
      {% for ivar in (condition_vars = @type.instance_vars.select { |iv| iv.annotation(WhereCondition) }) %}
        if %value{ivar} = @{{ivar.name}}
          if first
            str << " WHERE "
            first = false
          else
            str << " AND "
          end

          %value{ivar}.to_s(str)
        end
      {% end %}
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
      str << where_clause
    end
  end

  private def load_batch(batch_no, batch_size)
    sql = "#{find_all_query} LIMIT #{batch_size} OFFSET #{batch_no * batch_size}"
    begin
      db.query(sql) do |res|
        load_many_from_result(res)
      end
    rescue err
      raise DBError.new(err, sql)
    end
  end

  private def collection
    @collection ||=
      begin
        sql = find_all_query
        begin
          db.query(sql) do |res|
            load_many_from_result(res)
          end
        rescue err
          raise DBError.new(err, sql)
        end
      end
  end
end
