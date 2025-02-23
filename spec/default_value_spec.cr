require "./spec_helper"

class DefaultValueModel < Orma::Record
  id_column id : Int64
  column active : Bool = true
end

describe "DefaultValueModel" do
  describe "setting attribute default values" do
    it "returns the default value when the attribute is queried" do
      DefaultValueModel.new(id: 4_i64).active.should eq(true)
    end

    it "overwrites the default value when explicitly set" do
      DefaultValueModel.new(id: 4_i64, active: false).active.should eq(false)
    end
  end
end
