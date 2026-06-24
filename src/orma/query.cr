abstract class Orma::Query
  annotation WhereCondition; end
  annotation OrderColumn; end

  abstract def load_many_from_result(res)

  private class Statement
    getter args = [] of DB::Any

    def initialize(@db_adapter : Orma::DbAdapters::Base, select_clause, table_name)
      @sql = IO::Memory.new
      @has_where_condition = false
      @sql << "SELECT #{select_clause} FROM #{table_name}"
    end

    def sql
      @sql.to_s
    end

    def add_where_condition(name, value)
      @sql << (@has_where_condition ? " AND " : " WHERE ")
      @has_where_condition = true
      value.to_sql_where_condition(@sql, @db_adapter, args, name)
    end

    def add_order_clause(orderings)
      return unless orderings.any?

      @sql << " ORDER BY "
      orderings.join(@sql, ", ")
    end

    def add_limit(limit)
      return unless limit

      @sql << " LIMIT "
      add_parameter(limit)
    end

    def add_offset(offset)
      @sql << " OFFSET "
      add_parameter(offset)
    end

    private def add_parameter(value : DB::Any)
      @sql << @db_adapter.parameter_placeholder(args)
      args << value
    end
  end

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

  private def add_where_clause(statement : Statement)
    {% for ivar in (condition_vars = @type.instance_vars.select { |iv| iv.annotation(WhereCondition) }) %}
      if %value{ivar} = @{{ivar.name}}
        statement.add_where_condition(%value{ivar}.name, %value{ivar}.value)
      end
    {% end %}
  end

  private def count_query : Statement
    build_query("COUNT(*)", include_limit: false)
  end

  private def find_all_query : Statement
    build_query("*")
  end

  private def build_query(select_clause, *, include_limit = true) : Statement
    statement = Statement.new(db_adapter, select_clause, table_name)
    add_where_clause(statement)
    statement.add_order_clause(orderings)
    statement.add_limit(@limit) if include_limit
    statement
  end

  private def load_batch(batch_no, batch_size)
    statement = build_query("*", include_limit: false)
    statement.add_limit(batch_size.to_i64)
    statement.add_offset((batch_no * batch_size).to_i64)
    begin
      db.query(statement.sql, args: statement.args) do |res|
        load_many_from_result(res)
      end
    rescue err
      raise DBError.new(err, statement.sql)
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
