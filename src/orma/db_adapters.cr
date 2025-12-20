# :nodoc:
module Orma::DbAdapters
  # Used by `Orma::Record` continuous migration to describe the desired column
  # constraint state (some fields are tri-state, e.g. `not_null`).
  record DesiredColumnConstraints, default_sql : String?, not_null : Bool?
end
