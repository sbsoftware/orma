require "../../../src/orma"
require "./comment"

class MutualAssociationsPost < Orma::Record
  id_column id : Int64
  column title : String
  has_many_of MutualAssociationsComment
end
