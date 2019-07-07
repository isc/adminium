require 'uri'
require 'sequel'

# So that Sequel::Postgres::PGArray used in ResourcesHelper is loaded
# even though we didn't connect to a Postgres database yet.
Sequel.extension :pg_array, :pg_array_ops, :pg_hstore, :pg_json_ops
Sequel.extension :named_timezones
Sequel.tzinfo_disambiguator = proc {|_datetime, periods| periods.first}

class Generic
  PG_SYSTEM_TABLES = %i(pg_stat_activity pg_stat_statements pg_stat_all_indexes pg_stat_user_tables
                        pg_statio_user_tables pg_statio_user_indexes).freeze
  STATEMENT_TIMEOUT = 20_000
  attr_accessor :db_name, :account_id, :db, :account
  attr_reader :current_adapter

  def initialize account, opts = {}
    @account_id, @account = account.id, account
    establish_connection account.db_url, opts
  end

  def cleanup
    @db&.disconnect
  end

  def associations
    return @associations if @associations
    ActiveSupport::Notifications.instrument :associations_discovery do
      @associations = Rails.cache.fetch "account:#{@account_id}:associations", expires_in: 10.minutes do
        @associations = []
        tables.each do |table|
          begin
            discover_associations_through_foreign_keys table
            discover_associations_through_conventions table
          rescue Sequel::Error => e
            # A table with no columns generates a Sequel::Error for instance
            Airbrake.notify e
          end
        end
        @associations
      end
    end
    @associations
  end

  def discover_associations_through_foreign_keys table
    foreign_keys[table]&.each do |foreign_key|
      @associations |= [{foreign_key: foreign_key[:column], primary_key: foreign_key[:primary_key],
                         referenced_table: foreign_key[:to_table], table: table}]
    end
  end

  def discover_associations_through_conventions table
    schema(table).each do |name, info|
      next unless (name.to_s.ends_with? '_id') && (info[:type] == :integer)
      owner = name.to_s.gsub(/_id$/, '')
      owner_table = owner.tableize.to_sym
      if tables.include? owner_table
        @associations |= [{foreign_key: name, primary_key: :id, referenced_table: owner_table, table: table}]
      elsif schema(table).map(&:first).include? "#{owner}_type".to_sym
        @associations |= [{foreign_key: name, primary_key: :id, referenced_table: nil, table: table, polymorphic: true}]
      end
    end
  rescue Sequel::DatabaseError
    # don't fuck up everything when there is a freaky table which doesn't exist
  end

  def foreign_keys
    @foreign_keys ||= Rails.cache.fetch "foreign_keys:#{@account_id}", expires_in: 2.minutes do
      query = postgresql? ? postgresql_foreign_keys_query : mysql_foreign_keys_query
      fk_info = @db[query]
      foreign_keys = {}
      fk_info.each do |row|
        foreign_keys[row[:table_name].to_sym] ||= []
        foreign_keys[row[:table_name].to_sym] <<
          {column: row[:column].to_sym, to_table: row[:to_table].to_sym, primary_key: row[:primary_key].to_sym}
      end
      foreign_keys
    end
  end

  def mysql_foreign_keys_query
    %(
      SELECT fk.referenced_table_name as 'to_table'
            ,fk.referenced_column_name as 'primary_key'
            ,fk.column_name as 'column'
            ,fk.constraint_name as 'name'
            ,fk.table_name as 'table_name'
      FROM information_schema.key_column_usage fk
      WHERE fk.referenced_column_name is not null
        AND fk.table_schema = '#{db_name}'
    )
  end

  def postgresql_foreign_keys_query
    %(
      SELECT t2.relname AS to_table, a1.attname AS column, a2.attname AS primary_key, t1.relname as table_name
      FROM pg_constraint c
      JOIN pg_class t1 ON c.conrelid = t1.oid
      JOIN pg_class t2 ON c.confrelid = t2.oid
      JOIN pg_attribute a1 ON a1.attnum = c.conkey[1] AND a1.attrelid = t1.oid
      JOIN pg_attribute a2 ON a2.attnum = c.confkey[1] AND a2.attrelid = t2.oid
      JOIN pg_namespace t3 ON c.connamespace = t3.oid
      WHERE c.contype = 'f'
        AND t3.nspname = ANY (current_schemas(false))
      ORDER BY c.conname
    )
  end

  def tables
    return @tables if @tables
    # Fetching tables, views and materialized view all at once for PG
    @tables = postgresql? ? @db.send(:pg_class_relname, %w(r v m), {}) : (@db.tables + @db.views)
    @tables -= %i(ar_internal_metadata)
    @tables.sort!
    @account.update_column :tables_count, @tables.size if @account.tables_count != @tables.size
    @tables.concat PG_SYSTEM_TABLES - %i(pg_stat_statements) if postgresql?
    @tables
  end

  def user_tables
    tables - PG_SYSTEM_TABLES
  end

  def system_table? table
    PG_SYSTEM_TABLES.include? table.to_sym
  end

  def indexes table
    db.indexes(Sequel.identifier(table))
  end

  def detailed_indexes table
    return indexes(table) unless postgresql?
    result = db[:pg_indexes].select(:indexname, :indexdef).where(tablename: table).to_a
    result.each do |row|
      row[:unique] = row[:indexdef]['CREATE UNIQUE INDEX'].present?
      row[:indexdef] = row[:indexdef].split(' USING ').second
    end
    result.index_by {|r| r[:indexname]}
  end

  def table_comments tables
    return [] unless postgresql?
    @db.tables do |ds|
      ds = ds.join(:pg_description, objoid: Sequel[:pg_class][:oid]).select(:relname, :description, :objsubid)
      ds = if tables.nil? || tables.many?
             ds.where(objsubid: 0)
           else
             ds.where(relname: tables)
           end
      ds.to_a
    end
  end

  def column_comments table
    return [] unless postgresql?
    @db[Sequel.qualify(:pg_catalog, :pg_attribute)]
      .select(:attname, Sequel.function(:col_description, :attrelid, :attnum))
      .where(attrelid: Sequel.lit("'\"#{table}\"'::regclass")).where {attnum > 0}.exclude(attisdropped: true).to_a
      .select {|row| row[:col_description].present? }
      .map {|row| [row[:attname], row[:col_description]]}.to_h
  end

  def schema table
    raise TableNotFoundException, table unless tables.include? table
    @schema ||= {}
    @schema[table] || (@schema[table] = @db.schema(Sequel.identifier(table)))
  end

  def table table_name
    table_name = table_name.to_sym
    raise TableNotFoundException, table_name unless tables.include? table_name
    @db[Sequel.identifier table_name]
  end

  def db_size
    sql = if mysql?
            "select sum(data_length + index_length) as fulldbsize FROM information_schema.TABLES
            WHERE table_schema = '#{db_name}'"
          else
            "select pg_database_size('#{db_name}') as fulldbsize"
          end
    @db[sql].first[:fulldbsize].to_i
  end

  def table_sizes table_list
    query =
      if mysql?
        cond = "AND table_name in (#{table_list.map {|t| "'#{t}'"}.join(', ')})" if table_list.present?
        db["select table_name, data_length + index_length, data_length from information_schema.TABLES
            WHERE table_schema = '#{db_name}' #{cond}"]
      else
        where_hash = { nspname: search_path, relkind: 'r' }
        where_hash[:relname] = table_list.map(&:to_s) if table_list
        db[:pg_class]
          .join(:pg_namespace, oid: :relnamespace)
          .select(:relname,
                  Sequel.lit('pg_total_relation_size(pg_class.oid)'), Sequel.lit('pg_relation_size(pg_class.oid)'))
          .where(where_hash)
      end
    query.map(&:values).index_by(&:first)
  end

  def table_counts table_list
    table_list ||= tables
    table_list = table_list.map(&:to_s)
    query = if postgresql?
              db.from(:pg_stat_user_tables).select(:relname, :n_live_tup).where(relname: table_list)
            else
              db.from(Sequel[:INFORMATION_SCHEMA][:TABLES])
                .select(:table_name, :table_rows).where(table_schema: @db_name).where(table_name: table_list)
            end
    query.to_a.map(&:values).to_h
  end

  def establish_connection db_url, opts
    # TODO: there is a read_timeout option for mysql
    uri = URI.parse db_url
    uri.scheme = 'postgres' if uri.scheme == 'postgresql'
    uri.scheme = 'mysql2' if uri.scheme == 'mysql'
    @db_name = (uri.path || '').split('/')[1]
    @current_adapter = uri.scheme
    opts[:logger] ||= Rails.logger
    @db = Sequel.connect uri.to_s, opts.merge(keep_reference: false, connect_timeout: 5)
    if postgresql?
      @db.execute 'SET application_name to \'Adminium\''
      statement_timeout
      @db.extension :pg_array, :error_sql
      @db.extension :pg_hstore if @db.from(:pg_type).where(typtype: %w(b e), typname: 'hstore').get(:oid)
      @db.schema_parse_complete
    end
    @db.extension :named_timezones
    @db.timezone = ActiveSupport::TimeZone.new(@account.database_time_zone).tzinfo.name
    Sequel.application_timezone = ActiveSupport::TimeZone.new(@account.application_time_zone).tzinfo.name
  end

  def postgresql?
    current_adapter == 'postgres'
  end

  def mysql?
    current_adapter == 'mysql2'
  end

  def statement_timeout value = STATEMENT_TIMEOUT
    @db.execute "SET statement_timeout to #{value}" if postgresql?
  end

  def with_timeout
    statement_timeout 200
    yield
  rescue Sequel::DatabaseError
    nil
  ensure
    statement_timeout
  end

  def search_path
    @db.opts[:search_path]&.split(',') || %w(public)
  end

  class TableNotFoundException < RuntimeError
    attr_reader :table_name
    def initialize table_name
      @table_name = table_name
    end
  end
end
