require "db"
require "./db_adapters/*"
require "./attribute"
require "./query"
require "../ext/*"
require "digest/sha256"
require "crypto/bcrypt/password"

module Orma
  abstract class Record
    @@db : DB::Database?
    @@observers = [] of Proc(self, Nil)

    annotation Orma::IdColumn; end
    annotation Orma::Column; end
    annotation Orma::Deprecated; end

    macro id_column(type_decl)
      @[Orma::IdColumn]
      _column({{type_decl}})
      _define_setter({{type_decl}})
    end

    macro column(type_decl)
      @[Orma::Column]
      _column({{type_decl}})
      _define_setter({{type_decl}})
    end

    macro deprecated_column(type_decl)
      @[Orma::Column]
      @[Orma::Deprecated]
      _column({{type_decl}})
    end

    macro _column(type_decl)
      getter {{type_decl.var}} : ::Orma::Attribute({{type_decl.type}}) = ::Orma::Attribute({{type_decl.type}}).new(::{{@type.resolve}}, {{[type_decl.var.symbolize, type_decl.value].splat}})

      def self.{{type_decl.var}}(value)
        ::Orma::Attribute({{type_decl.type}}).new({{@type.resolve}}, {{type_decl.var.symbolize}}, value)
      end
    end

    macro _define_setter(type_decl)
      def {{type_decl.var}}=(new_val)
        {{type_decl.var}}.value = new_val
      end
    end

    macro password_column(name)
      @[Orma::Column]
      getter {{name.id}}_hash : ::Orma::Attribute(String?) = ::Orma::Attribute(String?).new(::{{@type.resolve}}, {{name.id.symbolize}}, nil)

      def verify_{{name.id}}(verified_password)
        return false unless %pw_hash = {{name.id}}_hash.value

        sha256_digest = Digest::SHA256.new
        sha256_digest << verified_password
        bcrypt_hash = Crypto::Bcrypt::Password.new(%pw_hash)
        bcrypt_hash.verify(sha256_digest.hexfinal)
      end

      def {{name.id}}=(new_password)
        sha256_digest = Digest::SHA256.new
        sha256_digest << new_password
        bcrypt_hash = Crypto::Bcrypt::Password.create(sha256_digest.hexfinal)
        @{{name.id}}_hash = ::Orma::Attribute(String?).new(self.class, {{name.id.symbolize}}, bcrypt_hash.to_s)
      end
    end

    macro has_many_of(klass)
      def {{klass.resolve.name.underscore.gsub(/::/, "_").id}}s
        {{klass}}.where({"{{@type.name.underscore.gsub(/::/, "_").id}}_id" => id})
      end
    end

    def self.db_connection_string
      ENV.fetch("DATABASE_URL", "postgres://postgres@localhost/postgres")
    end

    def self.db
      return @@db.not_nil! if @@db

      @@db = DB.open(db_connection_string)
    end

    def self.db_adapter
      return @@db_adapter.not_nil! if @@db_adapter

      driver_name = URI.parse(db_connection_string).scheme
      @@db_adapter = case driver_name
                     when "sqlite3"
                       DbAdapters::Sqlite3.new
                     when "postgres"
                       DbAdapters::Postgresql.new
                     else
                       raise "No DB adapter for driver '#{driver_name}'"
                     end
    end

    def self.add_observer(&block : Orma::Record -> Nil)
      @@observers << block
    end

    def self.notify_observers(instance)
      @@observers.each do |observer|
        observer.call(instance)
      end
    end

    def notify_observers
      self.class.notify_observers(self)
    end

    def db
      self.class.db
    end

    def self.table_name
      {{ @type.name.underscore.gsub(/::/, "_").stringify + "s"}}
    end

    def table_name
      self.class.table_name
    end

    def self.find(id)
      query_one("SELECT * FROM #{table_name} WHERE id=#{id} LIMIT 1")
    end

    def self.all
      Query(self).new
    end

    def self.where(conditions)
      Query(self).new(conditions_string(conditions))
    end

    def self.conditions_string(conditions)
      String.build do |str|
        conditions.each_with_index do |(col, val), i|
          str << col
          val.to_sql_where_condition(str)
          str << " AND " unless i == conditions.size - 1
        end
      end
    end

    def self.query_one(sql)
      db.query_one(sql) do |res|
        new.load_one_from_result(res)
      end
    end

    def self.load_many_from_result(res)
      instances = [] of self
      res.each do
        instances << new.load_one_from_result(res)
      end
      instances
    end

    def load_one_from_result(res)
      res.each_column do |column|
        {% begin %}
          case column
            {% for model_col in @type.instance_vars.select { |var| var.annotation(Orma::Column) || var.annotation(Orma::IdColumn) } %}
              when {{model_col.name.stringify}}, {{"_" + model_col.name.stringify + "_deprecated"}}
                @{{model_col.name}}.value = res.read(typeof(@{{model_col.name}}.value))
            {% end %}
          else
            puts "Unknown column name #{column}"
          end
        {% end %}
      end
      self
    end

    def save
      if id.value
        update_record
      else
        exec_res = insert_record
        # need to cast `#last_insert_id : Int64` to whatever `id`s type is
        self.id = {{@type.instance_vars.find { |v| v.annotation(Orma::IdColumn) }.type.type_vars.first.union_types.find { |tn| tn != Nil }}}.new(exec_res.last_insert_id)
      end
      notify_observers
    end

    def update_record
      query = String.build do |qry|
        qry << "UPDATE "
        qry << table_name
        qry << " SET "
        column_values.to_h.join(qry, ", ") do |(k, v), io|
          io << k
          v.to_sql_update_value(io)
        end
        qry << " WHERE id="
        qry << id.value
      end
      db.exec query
    end

    def insert_record
      {% if @type.instance_vars.any? { |v| v.name == "created_at".id } %}
        self.created_at = Time.utc
      {% end %}
      query = String.build do |qry|
        qry << "INSERT INTO "
        qry << table_name
        qry << "("
        column_values.keys.join(qry, ", ")
        qry << ") VALUES ("
        column_values.values.join(qry, ", ") { |v, io| v.to_sql_insert_value(io) }
        qry << ")"
      end
      db.exec query
    end

    macro column_values
      { {{@type.instance_vars.select { |var| var.annotation(Orma::Column) }.map { |var| "#{var.name}: @#{var.name}.value".id }.splat}} }
    end

    def self.continuous_migration!
      ensure_table_exists!
      ensure_columns_exist!
      deprecate_columns!
    end

    def self.ensure_table_exists!
      db.exec table_creation_sql
    end

    def self.ensure_columns_exist!
      column_names = query_column_names

      {% for var in @type.instance_vars %}
        {% if var.annotation(Orma::Column) && !var.annotation(Orma::Deprecated) %}
          unless column_names.includes?({{var.name.stringify}})
            db.exec "ALTER TABLE #{table_name} ADD COLUMN {{var.name.id}} #{db_type_for({{var.type.type_vars.first.union_types.find { |tn| tn != Nil }.id}})}"
          end
        {% end %}
      {% end %}
    end

    def self.deprecate_columns!
      column_deprecation_statements.each do |sql|
        db.exec sql
      end
    end

    def self.table_creation_sql
      String.build do |qry|
        qry << "CREATE TABLE IF NOT EXISTS "
        qry << table_name
        qry << "("
        db_column_statements.join(qry, ", ")
        qry << ")"
      end
    end

    def self.column_deprecation_statements
      column_names = query_column_names
      statements = [] of String

      {% for var in @type.instance_vars.select { |v| v.annotation(Orma::Deprecated) } %}
        if column_names.includes?({{var.name.id.stringify}})
          statements << "ALTER TABLE #{table_name} RENAME COLUMN {{var.name.id}} TO _{{var.name.id}}_deprecated"
        end
      {% end %}

      statements
    end

    def self.query_column_names
      db.query("SELECT * FROM #{table_name} LIMIT 1").column_names
    end

    macro db_column_statements
      [
        {% for var in @type.instance_vars.select { |v| v.annotation(Orma::IdColumn) } %}
          "{{var.name.id}} #{db_type_for({{var.type.type_vars.first.union_types.find { |tn| tn != Nil }.id}})} #{primary_key_column_statement}",
        {% end %}
        {% for var in @type.instance_vars.select { |v| v.annotation(Orma::Column) } %}
          "{{var.name.id}} #{db_type_for({{var.type.type_vars.first.union_types.find { |tn| tn != Nil }.id}})}",
        {% end %}
      ] of String
    end

    def self.db_type_for(klass)
      db_adapter.db_type_for(klass)
    end

    def self.primary_key_column_statement
      db_adapter.primary_key_column_statement
    end

    abstract def id
  end
end
