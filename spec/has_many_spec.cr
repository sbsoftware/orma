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

  class Post < TestRecord
    id_column id : Int64
    column title : String
    has_many_of HasManySpec::Comment
  end

  class Comment < TestRecord
    id_column id : Int64
    belongs_to HasManySpec::Post
    column body : String
  end
end

describe "the list class" do
  before_each do
    HasManySpec::Item.continuous_migration!
    HasManySpec::List.continuous_migration!
    HasManySpec::Post.continuous_migration!
    HasManySpec::Comment.continuous_migration!
  end

  after_each do
    Orma.reset_db!
  end

  describe "#items.to_a" do
    it "returns an empty Array for a new List" do
      list = HasManySpec::List.new(id: 594_i64)
      list.has_many_spec_items.to_a.should eq([] of HasManySpec::Item)
    end
  end

  describe "#comments.to_a" do
    it "supports a has_many_of declared before the reverse belongs_to class" do
      post = HasManySpec::Post.create(title: "post")
      HasManySpec::Comment.create(body: "hi", has_many_spec_post_id: post.id)

      post.has_many_spec_comments.to_a.map(&.body.value).should eq(["hi"])
    end
  end
end
