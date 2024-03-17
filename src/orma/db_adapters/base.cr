abstract class Orma::DbAdapters::Base
  abstract def db_type_for(klass)
  abstract def primary_key_column_statement
end
