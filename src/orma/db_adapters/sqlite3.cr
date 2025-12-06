require "./base"

# :nodoc:
class Orma::DbAdapters::Sqlite3 < Orma::DbAdapters::Base
  struct ColumnInfo
    getter name : String
    getter type : String
    getter notnull : Bool
    getter dflt_value : String?
    getter pk : Bool

    def initialize(res : DB::ResultSet | FakeResult)
      res.read(Int64) # cid, unused but preserves order
      @name = res.read(String)
      @type = res.read(String)
      @notnull = res.read(Int64) == 1
      @dflt_value = res.read(String?)
      @pk = res.read(Int64) > 0
    end
  end

  def db_type_for(klass)
    case klass
      in Int64.class then "INTEGER"
      in Int32.class then "INTEGER"
      in String.class then "TEXT"
      in Bool.class then "INTEGER"
      in Time.class then "INTEGER"
      in Slice(UInt8).class then "BLOB"
    end
  end

  def primary_key_column_statement
    "PRIMARY KEY AUTOINCREMENT"
  end

  def query_index_names
    names = [] of String

    db.query("SELECT name FROM sqlite_schema WHERE type='index'") do |res|
      res.each do
        res.each_column do |column|
          if column == "name"
            names << res.read(String)
          end
        end
      end
    end

    names
  end

  def enforce_not_null_with_default(table_name : String, column_name : String, default_sql : String)
    info = sqlite_column_info(table_name, column_name)
    return unless info
    return if info.notnull

    tmp_column = "#{column_name}__orma_tmp"

    db.exec "BEGIN"
    db.exec "ALTER TABLE #{table_name} ADD COLUMN #{tmp_column} #{info.type} NOT NULL DEFAULT #{default_sql}"
    db.exec "UPDATE #{table_name} SET #{tmp_column} = #{column_name}"
    db.exec "ALTER TABLE #{table_name} DROP COLUMN #{column_name}"
    db.exec "ALTER TABLE #{table_name} RENAME COLUMN #{tmp_column} TO #{column_name}"
    db.exec "COMMIT"
  rescue err
    db.exec "ROLLBACK" rescue nil
    raise err
  end

  def enforce_not_null_with_default? : Bool
    false
  end

  private def sqlite_column_info(table_name, column_name)
    db.query("PRAGMA table_info(#{table_name})") do |res|
      res.each do
        info = ColumnInfo.new(res)
        return info if info.name == column_name
      end
    end
    nil
  end
end
