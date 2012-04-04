require 'cgi'
require 'uri'

class Generic
  attr_accessor :models
  attr_reader :current_adapter

  class Base < ActiveRecord::Base
    cattr_accessor :account_id
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

    # fix to allow column names like save, changes
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
      res.account_id = @account_id
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
    Base.connection.tables.sort
  end

  def table table_name
    if account_module.constants.include? table_name.classify.to_sym
      account_module.const_get table_name.classify
    else
      raise TableNotFoundException.new(table_name)
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
