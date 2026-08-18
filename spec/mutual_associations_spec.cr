require "./spec_helper"
require "./fixtures/mutual_associations/post"

describe "mutual associations in separate files" do
  it "loads reciprocal has_many_of and belongs_to relations" do
    MutualAssociationsPost.continuous_migration!
    MutualAssociationsComment.continuous_migration!
    post = MutualAssociationsPost.create(title: "post")
    MutualAssociationsComment.create(body: "comment", mutual_associations_post_id: post.id)

    post.mutual_associations_comments.to_a.map(&.body.value).should eq(["comment"])
  ensure
    Orma.reset_db!
  end
end
