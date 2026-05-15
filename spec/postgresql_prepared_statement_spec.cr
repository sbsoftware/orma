require "./spec_helper"

module Orma::PostgresqlPreparedStatementSpec
  class FakeDB
    record Call, method : Symbol, sql : String, args : Array(DB::Any)

    class QueryCalled < Exception; end

    @@calls = [] of Call

    def self.calls
      @@calls
    end

    def self.reset!
      @@calls.clear
    end

    def query(sql, *, args : Enumerable? = nil, &)
      record_call(:query, sql, args)
    end

    def query_one(sql, *args_, args : Enumerable? = nil, &)
      record_call(:query_one, sql, args || args_)
    end

    def scalar(sql, *, args : Enumerable? = nil)
      record_call(:scalar, sql, args)
    end

    def exec(sql, *args_, args : Enumerable? = nil)
      record_call(:exec, sql, args || args_)
    end

    private def record_call(method, sql, args)
      call_args = [] of DB::Any
      args.try &.each { |arg| call_args << arg.as(DB::Any) }
      @@calls << Call.new(method, sql, call_args)
      raise QueryCalled.new
    end
  end

  class Record < TestRecord
    id_column id : Int64
    column name : String
    column age : Int32

    class FakePostgresqlAdapter
      def db_type_for(klass)
        raise "not used"
      end

      def primary_key_column_statement
        raise "not used"
      end

      def query_index_names
        raise "not used"
      end

      def query_column_names(table_name : String)
        raise "not used"
      end

      def sync_column_constraints(table_name : String, constraints : Hash(String, Orma::DbAdapters::DesiredColumnConstraints))
        raise "not used"
      end

      def add_parameter_placeholder(io : IO, args : Array(DB::Any), value : DB::Any)
        io << "$#{args.size + 1}"
        args << value
      end
    end

    @@db = FakeDB.new
    @@db_adapter = FakePostgresqlAdapter.new

    def self.db
      @@db
    end

    def self.db_adapter
      @@db_adapter
    end
  end

  private def self.db_args(*values)
    values.to_a.map(&.as(DB::Any))
  end

  private def self.expect_db_call(call, &)
    FakeDB.reset!

    expect_raises(Orma::DBError) do
      yield
    end

    FakeDB.calls.should eq([call])
  end

  describe "PostgreSQL prepared statements" do
    describe "via .find" do
      it "uses numbered placeholders" do
        expect_db_call(FakeDB::Call.new(:query_one, "SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE id=$1 LIMIT 1", db_args(2_i64))) do
          Record.find(2)
        end
      end
    end

    describe "via #reload" do
      it "uses numbered placeholders" do
        expect_db_call(FakeDB::Call.new(:query_one, "SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE id=$1 LIMIT 1", db_args(1_i64))) do
          Record.new(id: 1_i64, name: "Foo", age: 1).reload
        end
      end
    end

    describe "via #to_a" do
      it "uses numbered placeholders for scalar conditions" do
        expect_db_call(FakeDB::Call.new(:query, "SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE name=$1", db_args("test"))) do
          Record.where(name: "test").to_a
        end
      end

      it "uses numbered placeholders for list conditions" do
        expect_db_call(FakeDB::Call.new(:query, "SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE id IN ($1,$2)", db_args(1_i64, 2_i64))) do
          Record.where(id: [1_i64, 2_i64]).to_a
        end
      end

      it "continues numbering through limits" do
        expect_db_call(FakeDB::Call.new(:query, "SELECT * FROM orma_postgresql_prepared_statement_spec_records WHERE name=$1 LIMIT $2", db_args("test", 5_i64))) do
          Record.where(name: "test").limit(5).to_a
        end
      end
    end

    describe "via #count" do
      it "uses numbered placeholders" do
        expect_db_call(FakeDB::Call.new(:scalar, "SELECT COUNT(*) FROM orma_postgresql_prepared_statement_spec_records WHERE name=$1 AND age=$2", db_args("test", 1))) do
          Record.where(name: "test", age: 1).count
        end
      end
    end

    describe "via .create" do
      it "uses numbered placeholders" do
        expect_db_call(FakeDB::Call.new(:exec, "INSERT INTO orma_postgresql_prepared_statement_spec_records(name, age) VALUES ($1, $2)", db_args("Blah", 1))) do
          Record.create(name: "Blah", age: 1)
        end
      end
    end

    describe "via #save on an existing record" do
      it "uses numbered placeholders" do
        rec = Record.new(id: 1_i64, name: "Foo", age: 1)

        expect_db_call(FakeDB::Call.new(:exec, "UPDATE orma_postgresql_prepared_statement_spec_records SET name=$1, age=$2 WHERE id=$3", db_args("Bar", 1, 1_i64))) do
          rec.name = "Bar"
          rec.save
        end
      end
    end
  end
end
