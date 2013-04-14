require 'uri'
require 'sequel'
Sequel.extension :pagination

class Generic
  attr_accessor :models, :db_name, :account_id, :db
  attr_reader :current_adapter

  def initialize account
    @account_id = account.id
    establish_connection account.db_url
    # discover_classes_and_associations
  end

  def cleanup
    @db.disconnect
  end

  def discover_classes_and_associations
    discover_models
    discover_associations
  end

  def discover_associations
    models.each do |klass|
      if foreign_keys[klass.table_name].present?
        discover_associations_through_foreign_keys klass
      else
        discover_associations_through_conventions klass
      end
    end
  end

  def discover_associations_through_foreign_keys klass
    foreign_keys[klass.table_name].each do |foreign_key|
      options = {primary_key: foreign_key[:primary_key], foreign_key: foreign_key[:column]}
      owner_model = models.find{|model|model.table_name.downcase == foreign_key[:to_table].downcase}
      klass.belongs_to assoc_name(foreign_key[:to_table].downcase.singularize),
        options.merge(class_name: owner_model.name)
      owner_model.has_many assoc_name(klass.table_name), options.merge(class_name: klass.name)
    end
  end

  def discover_associations_through_conventions klass
    begin
      klass.columns.each do |column|
        next unless (column.name.ends_with? '_id') && (column.type == :integer)
        owner = column.name.gsub(/_id$/, '')
        begin
          if tables.include? owner.tableize
            account_module.const_get(class_name owner).has_many assoc_name(klass.table_name), class_name: klass.name
            klass.belongs_to assoc_name(owner), class_name: class_name(owner), foreign_key: column.name
          elsif klass.column_names.include? "#{owner}_type"
            klass.belongs_to assoc_name(owner), polymorphic: true, foreign_key: column.name
          end
        rescue NameError => e
          Rails.logger.warn "Failed for #{klass.table_name} belongs_to #{owner} : #{e.message}"
        end
      end
    rescue => e
      Rails.logger.warn "Association discovery failed for #{klass.name} : #{e.message}"
    end
  end
  
  def foreign_keys
    @foreign_keys ||= Rails.cache.fetch "foreign_keys:#{@account_id}", expires_in: 2.minutes do
      query = postgresql? ? postgresql_foreign_keys_query : mysql_foreign_keys_query
      fk_info = @db[query]
      foreign_keys = {}
      fk_info.each do |row|
        foreign_keys[row[:table_name]] ||= []
        foreign_keys[row[:table_name]] << {column: row[:column], to_table: row[:to_table], primary_key: row[:primary_key]}
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
    uri = URI.parse db_url
    uri.scheme = 'postgres' if uri.scheme == 'postgresql'
    uri.scheme = 'mysql2' if uri.scheme == 'mysql'
    @db_name = (uri.path || "").split("/")[1]
    @current_adapter = uri.scheme
    @db = Sequel.connect uri.to_s
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
