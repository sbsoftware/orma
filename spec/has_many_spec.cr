require "./spec_helper"

module HasManySpec
  class Item < TestRecord
    id_column id : Int64
    column has_many_spec_list_id : Int64
  end

  class List < TestRecord
    id_column id : Int64
    has_many_of HasManySpec::Item
  end
end

describe "the list class" do
  before_each do
    HasManySpec::Item.continuous_migration!
    HasManySpec::List.continuous_migration!
  end

  after_each do
    HasManySpec::List.db.close
  end

  describe "#items.to_a" do
    it "returns an empty Array for a new List" do
      list = HasManySpec::List.new(id: 594_i64)
      list.has_many_spec_items.to_a.should eq([] of HasManySpec::Item)
    end
  end
end
