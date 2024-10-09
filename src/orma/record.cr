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
    annotation Orma::Unique; end
    annotation Orma::Deprecated; end

    macro id_column(type_decl)
      @[Orma::IdColumn]
      _column({{type_decl}})
      _define_setter({{type_decl}})
    end

    macro column(type_decl, unique = false)
      @[Orma::Column]
      {% if unique %}
        @[Orma::Unique]
      {% end %}
      _column({{type_decl}})
      _define_setter({{type_decl}})
    end

    macro deprecated_column(type_decl)
      @[Orma::Column]
      @[Orma::Deprecated]
      _column({{type_decl}})
    end

    macro _column(type_decl)
      {% if type_decl.type.resolve.nilable? %}
        {% col_type = type_decl.type.resolve.union_types.find { |t| t != Nil } %}
      {% else %}
        {% col_type = type_decl.type %}
      {% end %}

      {% if type_decl.type.resolve.nilable? %}
        {% unless type_decl.value.nil? %}
          getter {{type_decl.var}} : ::Orma::Attribute({{col_type}})? = ::Orma::Attribute({{col_type}}).new(::{{@type.resolve}}, {{type_decl.var.symbolize}}, {{type_decl.value}})
        {% else %}
          getter {{type_decl.var}} : ::Orma::Attribute({{col_type}})?
        {% end %}
      {% else %}
        {% unless type_decl.value.nil? %}
          getter {{type_decl.var}} : ::Orma::Attribute({{type_decl.type}}) = ::Orma::Attribute({{type_decl.type}}).new(::{{@type.resolve}}, {{type_decl.var.symbolize}}, {{type_decl.value}})
        {% else %}
          getter {{type_decl.var}} : ::Orma::Attribute({{type_decl.type}})
        {% end %}
      {% end %}

      def self.{{type_decl.var}}(value)
        ::Orma::Attribute({{col_type}}).new({{@type.resolve}}, {{type_decl.var.symbolize}}, value)
      end
    end

    macro _set_attribute(name, value)
      if %var = @{{name}}
        %var.value = {{value}}
      else
        @{{name}} = ::Orma::Attribute.new(self.class, {{name.symbolize}}, {{value}})
      end
    end

    macro _define_setter(type_decl)
      def {{type_decl.var}}=(_new_val : Nil)
        @{{type_decl.var}} = nil
      end

      def {{type_decl.var}}=(new_val)
        _set_attribute({{type_decl.var}}, new_val)
      end
    end

    macro password_column(name)
      @[Orma::Column(setter: {{name.id}}, transform_in: generate_{{name.id}}_hash)]
      getter {{name.id}}_hash : ::Orma::Attribute(String)?

      def verify_{{name.id}}(verified_password : String)
        return false unless %pw_hash = {{name.id}}_hash.try(&.value)

        sha256_digest = Digest::SHA256.new
        sha256_digest << verified_password
        bcrypt_hash = Crypto::Bcrypt::Password.new(%pw_hash)
        bcrypt_hash.verify(sha256_digest.hexfinal)
      end

      def verify_{{name.id}}(_pw : Nil)
        false
      end

      def {{name.id}}=(new_password : String)
        _set_attribute({{name.id}}_hash, generate_{{name.id}}_hash(new_password))
      end

      def {{name.id}}=(_pw : Nil)
        @{{name.id}}_hash = nil
      end

      def generate_{{name.id}}_hash(input)
        sha256_digest = Digest::SHA256.new
        sha256_digest << input
        Crypto::Bcrypt::Password.create(sha256_digest.hexfinal).to_s
      end
    end

    macro has_many_of(klass)
      def {{klass.resolve.name.underscore.gsub(/::/, "_").id}}s
        {{klass}}.where({"{{@type.name.underscore.gsub(/::/, "_").id}}_id" => id})
      end
    end

    def initialize(**args : **T) forall T
      {% for key in T.keys.map(&.id) %}
        {% if ivar = @type.instance_vars.select { |iv| iv.annotation(Orma::Column) || iv.annotation(Orma::IdColumn) }.reject { |iv| iv.annotation(Orma::Deprecated) }.find { |iv| iv.id == key || ((ann = iv.annotation(Orma::Column)) && ann[:setter].id == key)} %}
          {% if !ivar.type.nilable? && T[key].nilable? %}
            {% raise "Type of `#{key}` argument is nilable, but `@#{ivar}` is not" %}
          {% end %}

          unless (%attr{ivar} = args[{{key.symbolize}}]).nil?
            {% if (ann = ivar.annotation(Orma::Column)) && (transform_in = ann[:transform_in]) %}
              %attr{ivar} = {{transform_in}}(%attr{ivar})
            {% end %}
            @{{ivar}} = ::Orma::Attribute.new(self.class, {{key.symbolize}}, %attr{ivar})
          else
            {% unless ivar.type.nilable? || ivar.has_default_value? %}
              raise "{{key}} can not be nil"
            {% end %}
          end
        {% else %}
          {% raise "Not a property: #{key}" %}
        {% end %}
      {% end %}
    end

    def initialize(db_res : DB::ResultSet | FakeResult)
      {% begin %}
        {% for model_col in @type.instance_vars.select { |var| var.annotation(Orma::Column) || var.annotation(Orma::IdColumn) } %}
          %value{model_col.id} = nil
        {% end %}

        db_res.each_column do |column|
          case column
            {% for model_col in @type.instance_vars.select { |var| var.annotation(Orma::Column) || var.annotation(Orma::IdColumn) } %}
              when {{model_col.name.stringify}}, {{"_" + model_col.name.stringify + "_deprecated"}}
                {% col_type = model_col.type.union_types.find { |t| t != Nil }.type_vars.first %}
                {% read_type = model_col.type.nilable? ? "#{col_type}?".id : col_type %}
                %value{model_col.id} = db_res.read({{read_type}})
            {% end %}
          end
        end
        {% for model_col in @type.instance_vars.select { |var| var.annotation(Orma::Column) || var.annotation(Orma::IdColumn) } %}
          unless %value{model_col.id}.nil?
            @{{model_col.name}} = ::Orma::Attribute.new(self.class, {{model_col.name.symbolize}}, %value{model_col.id})
          else
            {% unless model_col.type.nilable? || model_col.has_default_value? %}
              raise "nil value encountered for `@{{model_col}}`"
            {% end %}
          end
        {% end %}
      {% end %}
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
                       DbAdapters::Sqlite3.new(db)
                     when "postgres"
                       DbAdapters::Postgresql.new(db)
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
        new(res)
      end
    end

    def self.load_many_from_result(res)
      instances = [] of self
      res.each do
        instances << new(res)
      end
      instances
    end

    def save
      if id
        update_record
      else
        exec_res = insert_record
        # need to cast `#last_insert_id : Int64` to whatever `id`s type is
        {% if id_type = @type.instance_vars.find { |v| v.annotation(Orma::IdColumn) }.type.union_types.find { |t| t != Nil }.type_vars.first %}
          self.id = {{id_type}}.new(exec_res.last_insert_id)
        {% else %}
          {% raise "No `id` column defined on #{@type}" %}
        {% end %}
      end
      notify_observers
    end

    def update_record
      unless _id = id.try(&.value)
        raise "Cannot update record without `id`"
      end

      {% if @type.instance_vars.any? { |v| v.name == "updated_at".id && v.annotation(Orma::Column) } %}
        self.updated_at = Time.utc
      {% end %}

      query = String.build do |qry|
        qry << "UPDATE "
        qry << table_name
        qry << " SET "
        column_values.to_h.join(qry, ", ") do |(k, v), io|
          io << k
          v.to_sql_update_value(io)
        end
        qry << " WHERE id="
        qry << _id
      end
      db.exec query
    end

    def insert_record
      {% if @type.instance_vars.any? { |v| v.name == "created_at".id && v.annotation(Orma::Column) } %}
        self.created_at ||= Time.utc
      {% end %}
      {% if @type.instance_vars.any? { |v| v.name == "updated_at".id && v.annotation(Orma::Column) } %}
        self.updated_at ||= Time.utc
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
      { {{@type.instance_vars.select { |var| var.annotation(Orma::Column) }.map { |var| "#{var.name}: @#{var.name}.try(&.value)".id }.splat}} }
    end

    def self.continuous_migration!
      ensure_table_exists!
      ensure_columns_exist!
      ensure_unique_indexes_exist!
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
            db.exec "ALTER TABLE #{table_name} ADD COLUMN {{var.name.id}} #{db_type_for({{var.type.union_types.find { |t| t != Nil }.type_vars.first.id}})}"
          end
        {% end %}
      {% end %}
    end

    def self.ensure_unique_indexes_exist!
      index_names = db_adapter.query_index_names

      {% for ivar in @type.instance_vars %}
        {% if ivar.annotation(Orma::Column) && ivar.annotation(Orma::Unique) && !ivar.annotation(Orma::Deprecated) %}
          index_name = "idx_#{table_name}_{{ivar}}"
          unless index_names.includes?(index_name)
            db.exec "CREATE UNIQUE INDEX #{index_name} ON #{table_name} ({{ivar}})"
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
          "{{var.name.id}} #{db_type_for({{var.type.union_types.find { |t| t != Nil }.type_vars.first.id}})} #{primary_key_column_statement}",
        {% end %}
        {% for var in @type.instance_vars.select { |v| v.annotation(Orma::Column) } %}
          "{{var.name.id}} #{db_type_for({{var.type.union_types.find { |t| t != Nil }.type_vars.first.id}})}",
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

    def ==(other : self)
      id == other.id
    end
  end
end

require "./record/from_http_params"
