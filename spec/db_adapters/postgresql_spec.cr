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
end
