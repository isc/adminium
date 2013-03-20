require 'cgi'
require 'uri'

class Generic
  attr_accessor :models
  attr_reader :current_adapter

  def initialize account
    @account_id = account.id
    connection = build_connection_from_db_url account.db_url
    discover_classes_and_associations! connection
  end

  def account_module
    return @account_module if @account_module
    module_name = "Account_#{@account_id}"
    @account_module = self.class.const_get module_name, false
  rescue NameError
    @account_module = self.class.const_set module_name, Module.new
  end

  def cleanup
    self.class.send :remove_const, @account_module.name.demodulize if @account_module
    ActiveSupport::DescendantsTracker.send(:class_variable_get, '@@direct_descendants').delete_if do |key, value|
      key.name.match 'Generic::'
    end
  end

  def discover_classes_and_associations! connection_specification
    Base.establish_connection connection_specification
    discover_models
    discover_associations
  end

  def discover_models
    account_module.constants(false).each {|const| account_module.send :remove_const, const }
    self.models = tables.map do |table|
      res = account_module.const_set table.classify, Class.new(Base)
      res.adminium_account_id = @account_id
      res.generic = self
      res.table_name = table
      def res.abstract_class?
        false
      end
      if res.primary_key.nil?
        if res.column_names.include? 'id'
          res.primary_key = 'id'
        else
          references = res.column_names.find_all {|c| c.ends_with? '_id'}
          references = res.column_names.find_all {|c| c =~ /\wId$/} if references.empty?
          if references.size > 1
            res.primary_keys = references
          else
            res.primary_key = res.column_names.first
          end
        end
      end
      res
    end
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
      assoc_name = "_adminium_#{foreign_key[:to_table].downcase.singularize}".to_sym
      owner_model = models.find{|model|model.table_name.downcase == foreign_key[:to_table].downcase}
      klass.belongs_to assoc_name, options.merge(class_name: owner_model.name)
      owner_model.has_many "_adminium_#{klass.table_name}".to_sym, options.merge(class_name: klass.name)
    end
  end

  def discover_associations_through_conventions klass
    begin
      klass.columns.each do |column|
        next unless (column.name.ends_with? '_id') && (column.type == :integer)
        owner = column.name.gsub(/_id$/, '')
        begin
          if tables.include? owner.tableize
            plural_assoc = "_adminium_#{klass.table_name}".to_sym
            account_module.const_get(owner.classify).has_many plural_assoc, class_name: klass.name
            klass.belongs_to "_adminium_#{owner}".to_sym, class_name: owner.classify, foreign_key: column.name
          elsif klass.column_names.include? "#{owner}_type"
            klass.belongs_to "_adminium_#{owner}".to_sym, polymorphic: true, foreign_key: column.name
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
      fk_info = Base.connection.select_all query
      foreign_keys = {}
      fk_info.each do |row|
        foreign_keys[row['table_name']] ||= []
        foreign_keys[row['table_name']] << {column: row['column'], to_table: row['to_table'], primary_key: row['primary_key']}
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
    @tables ||= Base.connection.tables.sort
  end

  def table table_name
    if tables.include? table_name
      account_module.const_get table_name.classify, false
    else
      raise TableNotFoundException.new(table_name)
    end
  end

  def db_name
    Base.connection.instance_variable_get('@config')[:database]
  end

  def db_size
    if mysql?
      sql = "select sum(data_length + index_length) as fulldbsize FROM information_schema.TABLES WHERE table_schema = '#{db_name}'"
      Base.connection.execute(sql).first.first
    else
      sql = "select pg_database_size('#{db_name}') as fulldbsize"
      Base.connection.execute(sql).first['fulldbsize']
    end
  end

  def connection
    Base.connection
  end

  def table_sizes table_list
    if mysql?
      return [] if table_list.try(:empty?)
      cond = "AND table_name in (#{table_list.map{|t|"'#{t}'"}.join(', ')})" if table_list.present?
      Base.connection.execute("select table_name, data_length + index_length, data_length from information_schema.TABLES WHERE table_schema = '#{db_name}' #{cond}").to_a
    else
      tables.map do |table|
        next if table_list && !table_list.include?(table)
        res = [table]
        res += Base.connection.execute("select pg_total_relation_size('\"#{table}\"') as fulltblsize, pg_relation_size('\"#{table}\"') as tblsize").first.values
      end.compact
    end
  end

  def build_connection_from_db_url db_url
    uri = URI.parse db_url
    connection = { adapter: uri.scheme, username: uri.user, password: uri.password,
      host: uri.host, port: uri.port, database: (uri.path || "").split("/")[1] }
    connection[:adapter] = 'postgresql' if connection[:adapter] == 'postgres'
    connection[:adapter] = 'mysql2' if connection[:adapter] == 'mysql'
    @current_adapter = connection[:adapter]
    params = CGI.parse(uri.query || '')
    params.each {|k, v| connection[k] = v.first }
    connection
  end

  def postgresql?
    current_adapter == 'postgresql'
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
