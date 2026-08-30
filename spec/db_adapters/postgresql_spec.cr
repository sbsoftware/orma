require "../spec_helper"

describe Orma::DbAdapters::Postgresql do
  db = uninitialized DB::Database
  adapter = Orma::DbAdapters::Postgresql.new(db)

  it "uses plain integer types for non-primary-key columns" do
    adapter.db_type_for(Int64).should eq("BIGINT")
    adapter.db_type_for(Int32).should eq("INTEGER")
  end

  it "uses serial integer types for primary-key columns" do
    adapter.primary_key_db_type_for(Int64).should eq("BIGSERIAL")
    adapter.primary_key_db_type_for(Int32).should eq("SERIAL")
  end

  it "uses Postgres binary storage for byte slices" do
    adapter.db_type_for(Slice(UInt8)).should eq("BYTEA")
  end

  it "adds a FOR UPDATE clause for row locks" do
    String.build { |io| adapter.add_lock_clause(io) }.should eq(" FOR UPDATE")
  end

  it "generates unique index SQL for multiple columns" do
    adapter.create_unique_index_sql("records", "idx_records_slug_account_id", ["slug", "account_id"]).should eq("CREATE UNIQUE INDEX idx_records_slug_account_id ON records (slug, account_id)")
  end
end
