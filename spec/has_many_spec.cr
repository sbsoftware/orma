require "./spec_helper"

module HasManySpec
  class Item < FakeRecord
    column has_many_spec_list_id : Int64
  end

  class List < FakeRecord
    has_many_of HasManySpec::Item
  end
end

describe "the list class" do
  before_each do
    FakeDB.reset
  end

  after_each do
    FakeDB.assert_empty!
  end

  describe "#items.to_a" do
    it "returns an empty Array for a new List" do
      list = HasManySpec::List.new(id: 594_i64)
      FakeDB.expect("SELECT * FROM has_many_spec_items WHERE has_many_spec_list_id=594")
      list.has_many_spec_items.to_a.should eq([] of HasManySpec::Item)
    end
  end
end
