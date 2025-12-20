require "./spec_helper"

describe Orma::ToSql do
  it "provides non-IO variants" do
    true.to_sql_value.should eq("TRUE")
    false.to_sql_value.should eq("FALSE")
    12_i64.to_sql_value.should eq("12")
    "O'Reilly".to_sql_value.should eq("'O''Reilly'")
    nil.to_sql_value.should eq("NULL")
    [1_i64, 2_i64].to_sql_value.should eq("(1,2)")

    true.sql_eq_operator.should eq("=")
    nil.sql_eq_operator.should eq(" IS ")
    [1_i64, 2_i64].sql_eq_operator.should eq(" IN ")

    true.to_sql_where_condition.should eq("=TRUE")
    nil.to_sql_where_condition.should eq(" IS NULL")
    [1_i64, 2_i64].to_sql_where_condition.should eq(" IN (1,2)")

    true.to_sql_update_value.should eq("=TRUE")
    nil.to_sql_update_value.should eq("=NULL")

    true.to_sql_insert_value.should eq("TRUE")
  end
end
