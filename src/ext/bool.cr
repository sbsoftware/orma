require "../orma/to_sql"

struct Bool
  include Orma::ToSql

  def to_sql_value(io : IO)
    if self
      io << "TRUE"
    else
      io << "FALSE"
    end
  end

  def self.from_http_param(str)
    case str
    when "true", "1" then true
    when "false", "0" then false
    end
  end
end
