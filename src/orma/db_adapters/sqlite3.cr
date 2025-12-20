require "./base"

# :nodoc:
class Orma::DbAdapters::Sqlite3 < Orma::DbAdapters::Base
  struct ColumnInfo
    getter name : String
    getter type : String
    getter notnull : Bool
    getter dflt_value : String?
    getter pk : Bool

    def initialize(res : DB::ResultSet)
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
    in Int64.class        then "INTEGER"
    in Int32.class        then "INTEGER"
    in String.class       then "TEXT"
    in Bool.class         then "INTEGER"
    in Time.class         then "INTEGER"
    in Slice(UInt8).class then "BLOB"
    end
  end

  def primary_key_column_statement
    "PRIMARY KEY AUTOINCREMENT"
  end

  def query_column_names(table_name : String) : Array(String)
    sqlite_column_infos(table_name).map(&.name)
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

  def sync_column_constraints(table_name : String, constraints : Hash(String, Orma::DbAdapters::DesiredColumnConstraints))
    infos = sqlite_column_infos(table_name)
    return if infos.empty?

    needs_rebuild = infos.any? do |info|
      desired = constraints[info.name]?
      next false unless desired

      desired_default = desired.default_sql
      desired_not_null = desired.not_null.nil? ? info.notnull : desired.not_null.not_nil!

      info.dflt_value != desired_default || info.notnull != desired_not_null
    end
    return unless needs_rebuild

    index_sqls = sqlite_object_sqls("index", table_name)
    trigger_sqls = sqlite_object_sqls("trigger", table_name)

    old_table = "#{table_name}__orma_old"
    db.exec "BEGIN"
    db.exec "ALTER TABLE #{table_name} RENAME TO #{old_table}"
    db.exec "CREATE TABLE #{table_name}(#{sqlite_column_definitions(infos, constraints)})"
    db.exec "INSERT INTO #{table_name}(#{infos.map(&.name).join(", ")}) SELECT #{infos.map(&.name).join(", ")} FROM #{old_table}"
    db.exec "DROP TABLE #{old_table}"
    index_sqls.each { |sql| db.exec sql }
    trigger_sqls.each { |sql| db.exec sql }
    sqlite_fix_sequence(table_name, infos)
    db.exec "COMMIT"
  rescue err
    db.exec "ROLLBACK" rescue nil
    raise err
  end

  private def sqlite_column_infos(table_name : String) : Array(ColumnInfo)
    infos = [] of ColumnInfo
    db.query("PRAGMA table_info(#{table_name})") do |res|
      res.each do
        infos << ColumnInfo.new(res)
      end
    end
    infos
  end

  private def sqlite_object_sqls(type : String, table_name : String) : Array(String)
    sqls = [] of String

    db.query("SELECT sql FROM sqlite_master WHERE type='#{type}' AND tbl_name='#{table_name}' AND sql IS NOT NULL") do |res|
      res.each do
        sqls << res.read(String)
      end
    end

    sqls
  end

  private def sqlite_column_definitions(
    infos : Array(ColumnInfo),
    constraints : Hash(String, Orma::DbAdapters::DesiredColumnConstraints),
  ) : String
    pk_count = infos.count(&.pk)
    raise "Composite primary keys are not supported" if pk_count > 1

    String.build do |io|
      infos.each_with_index do |info, idx|
        io << ", " if idx > 0

        io << info.name
        io << " "
        io << info.type

        if info.pk
          io << " "
          if info.type.upcase == "INTEGER"
            io << "PRIMARY KEY AUTOINCREMENT"
          else
            io << "PRIMARY KEY"
          end
          next
        end

        desired = constraints[info.name]?
        column_default_sql = desired ? desired.default_sql : info.dflt_value
        column_not_null = if desired && !desired.not_null.nil?
                            desired.not_null.not_nil!
                          else
                            info.notnull
                          end

        if column_default_sql
          io << " DEFAULT "
          io << column_default_sql
        end
        if column_not_null
          io << " NOT NULL"
        end
      end
    end
  end

  private def sqlite_fix_sequence(table_name : String, infos : Array(ColumnInfo))
    pk = infos.find(&.pk)
    return unless pk
    return unless pk.type.upcase == "INTEGER"

    db.exec "INSERT OR REPLACE INTO sqlite_sequence(name, seq) VALUES ('#{table_name}', (SELECT COALESCE(MAX(#{pk.name}), 0) FROM #{table_name}))"
  rescue
    # sqlite_sequence might not exist (no AUTOINCREMENT tables yet) and that's fine
  end
end
