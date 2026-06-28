require "./spec_helper"

describe Orma::ToSql do
  it "provides non-IO variants" do
    true.to_sql_value.should eq("TRUE")
    false.to_sql_value.should eq("FALSE")
    12_i64.to_sql_value.should eq("12")
    "O'Reilly".to_sql_value.should eq("'O''Reilly'")
    nil.to_sql_value.should eq("NULL")
    [1_i64, 2_i64].to_sql_value.should eq("(1,2)")

    true.to_sql_update_value.should eq("=TRUE")
    nil.to_sql_update_value.should eq("=NULL")

    true.to_sql_insert_value.should eq("TRUE")
  end

  it "represents where conditions without writing SQL" do
    condition = true.to_sql_where_condition
    condition.combinator.should eq(" AND ")
    condition.predicates.map(&.operator).should eq(["="])
    condition.predicates.first.values.first.parameter.should eq(true)

    condition = nil.to_sql_where_condition
    condition.predicates.map(&.operator).should eq([" IS "])
    condition.predicates.first.values.first.sql.should eq("NULL")

    condition = [1_i64, 2_i64].to_sql_where_condition
    condition.predicates.first.operator.should eq(" IN ")
    condition.predicates.first.wrap_values.should be_true
    condition.predicates.first.values.map(&.parameter).should eq([1_i64, 2_i64])

    condition = (1...10).to_sql_where_condition
    condition.predicates.map(&.operator).should eq([">=", "<"])
    condition.predicates.map { |predicate| predicate.values.first.parameter }.should eq([1_i64, 10_i64])
  end
end
