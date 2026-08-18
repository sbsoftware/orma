require "./post"

class MutualAssociationsComment < Orma::Record
  id_column id : Int64
  column body : String
  belongs_to MutualAssociationsPost
end
