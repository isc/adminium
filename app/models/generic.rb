require 'uri'
require 'sequel'
Sequel.extension :pagination

class Generic
  attr_accessor :models, :db_name, :account_id, :db
  attr_reader :current_adapter

  def initialize account
    @account_id = account.id
    establish_connection account.db_url
  end

  def cleanup
    @db.disconnect
  end
  
  def associations
    return @associations if @associations
    ActiveSupport::Notifications.instrument(:associations_discovery, at: Time.now) do
      @associations = Hash[tables.map {|t| [t, {belongs_to: {}, has_many: {}}]}]
      tables.each do |table|
        if foreign_keys[table].present?
          discover_associations_through_foreign_keys table
        else
          discover_associations_through_conventions table
        end
      end
    end
    @associations
  end

  def discover_associations_through_foreign_keys table
    foreign_keys[table].each do |foreign_key|
      @associations[table][:belongs_to][foreign_key[:to_table]] =
        @associations[foreign_key[:to_table]][:has_many][table] =
        {foreign_key: foreign_key[:column], primary_key: foreign_key[:primary_key], referenced_table: foreign_key[:to_table]}
    end
  end

  def discover_associations_through_conventions table
    schema(table).each do |name, info|
      next unless (name.to_s.ends_with? '_id') && (info[:type] == :integer)
      owner = name.to_s.gsub(/_id$/, '')
      owner_table = owner.tableize.to_sym
      if tables.include? owner_table
        @associations[table][:belongs_to][owner_table] =
          @associations[owner_table][:has_many][table] =
          {foreign_key: name, primary_key: :id, referenced_table: owner_table, table: table}
        # TODO polymorphic associations
        # elsif klass.column_names.include? "#{owner}_type"
        #   klass.belongs_to assoc_name(owner), polymorphic: true, foreign_key: column.name
      end
    end
  end
  
  def foreign_keys
    @foreign_keys ||= Rails.cache.fetch "foreign_keys:#{@account_id}", expires_in: 2.minutes do
      query = postgresql? ? postgresql_foreign_keys_query : mysql_foreign_keys_query
      fk_info = @db[query]
      foreign_keys = {}
      fk_info.each do |row|
        foreign_keys[row[:table_name].to_sym] ||= []
        foreign_keys[row[:table_name].to_sym] << {column: row[:column].to_sym, to_table: row[:to_table].to_sym, primary_key: row[:primary_key].to_sym}
      end
      foreign_keys
    end
  end

  def mysql_foreign_keys_query
    %{
      SELECT fk.referenced_table_name as 'to_table'
            ,fk.referenced_column_name as 'primary_key'
            ,fk.column_name as 'column'
            ,fk.constraint_name as 'name'
            ,fk.table_name as 'table_name'
      FROM information_schema.key_column_usage fk
      WHERE fk.referenced_column_name is not null
        AND fk.table_schema = '#{db_name}'
    }
  end

  def postgresql_foreign_keys_query
    %{
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
    }
  end

  def tables
    @tables ||= @db.tables.sort
  end
  
  def schema table
    raise TableNotFoundException.new(table) unless tables.include? table
    @schema ||= {}
    @schema[table] || (@schema[table] = @db.schema(table))
  end

  def table table_name
    table_name = table_name.to_sym
    if tables.include? table_name
      @db[table_name]
    else
      raise TableNotFoundException.new(table_name)
    end
  end

  def db_size
    sql = if mysql?
      "select sum(data_length + index_length) as fulldbsize FROM information_schema.TABLES WHERE table_schema = '#{db_name}'"
    else
      "select pg_database_size('#{db_name}') as fulldbsize"
    end
    @db[sql].first[:fulldbsize]
  end

  def table_sizes table_list
    table_list ||= tables
    if mysql?
      return [] if table_list.try(:empty?)
      cond = "AND table_name in (#{table_list.map{|t|"'#{t}'"}.join(', ')})" if table_list.present?
      Base.connection.execute("select table_name, data_length + index_length, data_length from information_schema.TABLES WHERE table_schema = '#{db_name}' #{cond}").to_a
    else
      table_list.map do |table|
        res = [table]
        res += @db["select pg_total_relation_size('\"#{table}\"') as fulltblsize, pg_relation_size('\"#{table}\"') as tblsize"].first.values
      end.compact
    end
  end

  def establish_connection db_url
    # TODO there is a read_timeout option for mysql
    uri = URI.parse db_url
    uri.scheme = 'postgres' if uri.scheme == 'postgresql'
    uri.scheme = 'mysql2' if uri.scheme == 'mysql'
    @db_name = (uri.path || "").split("/")[1]
    @current_adapter = uri.scheme
    @db = Sequel.connect uri.to_s, logger: Rails.logger
  end

  def postgresql?
    current_adapter == 'postgres'
  end

  def mysql?
    current_adapter == 'mysql2'
  end

  class TableNotFoundException < Exception
    attr_reader :table_name
    def initialize table_name
      @table_name = table_name
    end
  end

end
