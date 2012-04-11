require 'cgi'
require 'uri'

class Generic
  attr_accessor :models
  attr_reader :current_adapter

  class Base < ActiveRecord::Base
    cattr_accessor :adminium_account_id
    extend Settings

    def self.abstract_class?
      true
    end
    def self.original_name
      name.demodulize
    end
    def self.inheritance_column
    end

    def self.foreign_key? column_name
      column_name.ends_with?('_id') && reflections.keys.find {|assoc| assoc.to_s == column_name.gsub(/_id$/, '') }
    end
    
    def adminium_label
      if (label_column = self.class.settings.label_column)
        label = self[label_column]
      end
      label || "#{self.class.original_name.humanize} ##{self[self.class.primary_key]}"
    end

    # workaround to allow column names like save, changes.
    # can't edit those columns though
    def self.instance_method_already_implemented?(method)
      super
    rescue ActiveRecord::DangerousAttributeError
      false
    end
  end

  def initialize account
    @account_id = account.id
    connection = build_connection_from_db_url account.db_url
    discover_classes_and_associations! connection
  end

  def account_module
    return @account_module if @account_module
    module_name = "Account#{@account_id}"
    @account_module = self.class.const_get module_name
  rescue NameError
    @account_module = self.class.const_set module_name, Module.new
  end

  def cleanup
    self.class.send :remove_const, @account_module.name.demodulize if @account_module
  end

  def discover_classes_and_associations! connection_specification
    Base.establish_connection connection_specification
    discover_models
    discover_associations
  end

  def discover_models
    if models.present?
      account_module.constants.each {|const| account_module.remove_const const unless const == :Base }
      models.clear # need to explicitly clear in case the filling goes wrong
    end
    self.models = tables.map do |table|
      res = account_module.const_set table.classify, Class.new(Base)
      res.adminium_account_id = @account_id
      res.table_name = table
      def res.abstract_class?
        false
      end
      res.primary_key = res.column_names.first if res.primary_key.nil?
      res
    end
  end

  def discover_associations
    models.each do |klass|
      begin
        owners = klass.column_names.find_all {|c| c.ends_with? '_id'}.map {|c| c.gsub(/_id$/, '')}
        owners.each do |owner|
          begin
            if tables.include? owner.tableize
              account_module.const_get(owner.classify).has_many klass.table_name.to_sym
              klass.belongs_to owner.to_sym
            elsif klass.column_names.include? "#{owner}_type"
              klass.belongs_to owner.to_sym, polymorphic: true
            end
          rescue NameError => e
            Rails.logger.warn "Failed for #{klass.table_name} belongs_to #{owner} : #{e.message}"
          end
        end
      rescue => e
        Rails.logger.warn "Association discovery failed for #{klass.name} : #{e.message}"
      end
    end
  end

  def tables
    @tables ||= Base.connection.tables.sort
  end

  def table table_name
    if account_module.constants.include? table_name.classify.to_sym
      account_module.const_get table_name.classify
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
  
  def table_sizes table_list
    if mysql?
      return [] if table_list.try(:empty?)
      cond = "AND table_name in (#{table_list.map{|t|"'#{t}'"}.join(', ')})" if table_list.present?
      res = Base.connection.execute "select table_name, data_length + index_length, data_length from information_schema.TABLES WHERE table_schema = '#{db_name}' #{cond}"
      res.map {|table_row| table_row + [table(table_row.first).count] }
    else
      tables.map do |table|
        next if table_list && !table_list.include?(table)
        res = [table]
        res += Base.connection.execute("select pg_total_relation_size('#{table}') as fulltblsize, pg_relation_size('#{table}') as tblsize").first.values
        res << table(table).count
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
