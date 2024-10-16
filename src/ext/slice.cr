struct Slice(T)
  include Orma::ToSql

  def to_sql_value(io : IO)
    io << "x'"
    io << self.hexstring
    io << "'"
  end
end
