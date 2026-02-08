require "./spec_helper"

module BelongsToSpec
  class Post < TestRecord
    id_column id : Int64
    column title : String
  end

  class Comment < TestRecord
    id_column id : Int64
    belongs_to BelongsToSpec::Post
    column body : String
  end

  class OptionalComment < TestRecord
    id_column id : Int64
    belongs_to BelongsToSpec::Post, required: false
    column body : String
  end
end

describe "belongs_to macro" do
  before_each do
    BelongsToSpec::Post.continuous_migration!
    BelongsToSpec::Comment.continuous_migration!
    BelongsToSpec::OptionalComment.continuous_migration!
  end

  after_each do
    BelongsToSpec::OptionalComment.db.close
  end

  it "adds a required foreign key column by default" do
    BelongsToSpec::Comment.query_column_names.includes?("belongs_to_spec_post_id").should be_true
  end

  it "loads the associated record" do
    post = BelongsToSpec::Post.create(title: "post")
    comment = BelongsToSpec::Comment.create(body: "hi", belongs_to_spec_post_id: post.id)

    BelongsToSpec::Comment.find(comment.id).belongs_to_spec_post.title.should eq("post")
  end

  it "supports optional foreign keys (required: false)" do
    comment = BelongsToSpec::OptionalComment.create(body: "lonely")

    BelongsToSpec::OptionalComment.find(comment.id).belongs_to_spec_post.should be_nil
  end

  it "loads the associated record for optional foreign keys" do
    post = BelongsToSpec::Post.create(title: "post")
    comment = BelongsToSpec::OptionalComment.create(body: "hi", belongs_to_spec_post_id: post.id)

    BelongsToSpec::OptionalComment.find(comment.id).belongs_to_spec_post.not_nil!.title.should eq("post")
  end
end
