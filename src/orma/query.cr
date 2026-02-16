abstract class Orma::Query
  annotation WhereCondition; end
  annotation OrderColumn; end

  abstract def load_many_from_result(res)

  private record Statement, sql : String, args : Array(DB::Any)

  delegate :size, :each, :each_with_index, :map, :first, :first?, :last, :last?, :any?, :empty?, :all?, :none?, :select, :max_by, :min_by, :find, :find!, to: collection

  record Condition(T), name : String, value : T

  enum Direction
    Asc
    Desc

    def to_s(io : IO)
      io << self.to_s.upcase
    end
  end

  record Ordering, name : String, direction : Direction do
    def to_s(io : IO)
      io << name
      io << " "
      io << direction
    end
  end

  getter orderings : Array(Ordering) = [] of Ordering
  @limit : Int64?

  def initialize(**conditions : **K) forall K
    where(**conditions)
  end

  def initialize(conditions : Hash(String, K)) forall K
    where(conditions)
  end

  def where(**conditions : **K) forall K
    {% for key in K.keys.map(&.id) %}
      {% if ivar = @type.instance_vars.find { |iv| iv.annotation(WhereCondition) && iv.name.id == "#{key}_condition".id } %}
        {% type = ivar.type.union_types.find { |t| t != Nil }.type_vars.first %}
        @{{key}}_condition = Condition({{type}}?).new({{key.stringify}}, conditions[{{key.symbolize}}])
      {% else %}
        {% key.raise "No column: #{key}" %}
      {% end %}
    {% end %}

    self
  end

  def where(conditions : Hash(String, K)) forall K
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

    self
  end

  def limit(limit : Int)
    @limit = limit.to_i64
    self
  end

  def limit(_limit : Nil)
    @limit = nil
    self
  end

  def find_each(*, batch_size = 1000, &)
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
    statement = count_query
    begin
      db.scalar(statement.sql, args: statement.args).as(Int64)
    rescue err
      raise DBError.new(err, statement.sql)
    end
  end

  def to_a
    collection.dup.to_a
  end

  private def where_clause(args : Array(DB::Any))
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

          str << %value{ivar}.name
          append_condition_value(str, args, %value{ivar}.value)
        end
      {% end %}
    end
  end

  private def append_condition_value(io : IO, args : Array(DB::Any), value : Nil)
    io << " IS NULL"
  end

  private def append_condition_value(io : IO, args : Array(DB::Any), value : Array)
    io << " IN ("
    value.each_with_index do |item, index|
      io << ", " if index > 0
      io << "?"
      args << to_db_any(item)
    end
    io << ")"
  end

  private def append_condition_value(io : IO, args : Array(DB::Any), value : Orma::Attribute)
    append_condition_value(io, args, value.value)
  end

  private def append_condition_value(io : IO, args : Array(DB::Any), value)
    io << "=?"
    args << to_db_any(value)
  end

  private def to_db_any(value : DB::Any) : DB::Any
    value
  end

  private def to_db_any(value : Int) : DB::Any
    value.to_i64
  end

  private def to_db_any(value) : DB::Any
    value.as(DB::Any)
  end

  private def order_clause
    return nil unless orderings.any?

    String.build do |str|
      str << " ORDER BY "
      orderings.join(str, ", ")
    end
  end

  private def count_query : Statement
    build_query("COUNT(*)", include_limit: false)
  end

  private def find_all_query : Statement
    build_query("*")
  end

  private def build_query(select_clause, *, include_limit = true) : Statement
    args = [] of DB::Any
    sql = String.build do |str|
      str << "SELECT #{select_clause} FROM #{table_name}"
      str << where_clause(args)
      str << order_clause
      if include_limit
        str << limit_clause(args)
      end
    end
    Statement.new(sql, args)
  end

  private def limit_clause(args : Array(DB::Any))
    return nil unless limit = @limit

    args << limit
    " LIMIT ?"
  end

  private def load_batch(batch_no, batch_size)
    base = build_query("*", include_limit: false)
    sql = "#{base.sql} LIMIT ? OFFSET ?"
    args = base.args.dup
    args << batch_size.to_i64
    args << (batch_no * batch_size).to_i64
    begin
      db.query(sql, args: args) do |res|
        load_many_from_result(res)
      end
    rescue err
      raise DBError.new(err, sql)
    end
  end

  private def collection
    @collection ||=
      begin
        statement = find_all_query
        begin
          db.query(statement.sql, args: statement.args) do |res|
            load_many_from_result(res)
          end
        rescue err
          raise DBError.new(err, statement.sql)
        end
      end
  end
end
