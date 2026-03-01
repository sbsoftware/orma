require "./spec_helper"

module Orma::SharedDbSpec
  class MyRecord < TestRecord
    id_column id : Int64
  end

  class OtherRecord < TestRecord
    id_column id : Int64
  end

  describe "shared DB instance" do
    after_each do
      MyRecord.db.close
    end

    it "reuses one database and one pool for all record classes" do
      MyRecord.db.same?(OtherRecord.db).should be_true
      MyRecord.db.should be_a(DB::Database)
      OtherRecord.db.should be_a(DB::Database)
      MyRecord.db.as(DB::Database).pool.same?(OtherRecord.db.as(DB::Database).pool).should be_true
    end
  end
end
