require "./spec_helper"

class DefaultValueModel < Orma::Record
  id_column id : Int64?
  column active : Bool = true
end

describe "DefaultValueModel" do
  describe "setting attribute default values" do
    it "returns the default value when the attribute is queried" do
      DefaultValueModel.new.active.value.should eq(true)
    end

    it "overwrites the default value when explicitly set" do
      DefaultValueModel.new(active: false).active.value.should eq(false)
    end
  end
end
