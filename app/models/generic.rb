require 'cgi'
require 'uri'

class Generic
  cattr_accessor :models
  cattr_reader :current_adapter

  class Base < ActiveRecord::Base
    def self.abstract_class?
      true
    end
    def self.original_name
      name.split('::').last
    end
    set_inheritance_column { }
  end

  def self.connect_and_domain_discovery db_url
    @@current_db_url ||= nil
    return if @@current_db_url == db_url
    connection = Generic.build_connection_from_db_url db_url
    Generic.discover_classes_and_associations! connection
    @@current_db_url = db_url
  end

  def self.discover_classes_and_associations! connection_specification
    ActiveSupport::Notifications.instrument(:classes_and_associations_discovery, :at => Time.now) do
      Base.establish_connection connection_specification
      discover_models
      discover_associations
    end
  end
  
  def self.discover_models
    if models.present?
      constants.each {|const| remove_const const unless const == :Base }
      models.clear # need to explicitly clear in case the filling goes wrong
    end
    self.models = tables.map do |table|
      res = const_set table.classify, Class.new(Base)
      res.table_name = table
      res
    end
  end
  
  def self.discover_associations
    models.each do |klass|
      begin
        owners = klass.column_names.find_all {|c| c.ends_with? '_id'}.map {|c| c.gsub(/_id$/, '')}
        owners.each do |owner|
          begin
            const_get(owner.classify).has_many klass.table_name.to_sym
            klass.belongs_to owner.to_sym
          rescue NameError => e
            Rails.logger.warn "Failed for #{klass.table_name} belongs_to #{owner} : #{e.message}"
          end
        end
      rescue => e
        Rails.logger.warn "Association discovery failed for #{klass.name} : #{e.message}"
      end
    end
  end
  
  def self.tables
    Base.connection.tables.sort
  end

  def self.table table_name
    const_get table_name.classify
  rescue NameError
    raise "Couldn't get class for table #{table_name}, current constants : #{Generic.constants.inspect}"
  end
  
  def self.json_diagram
    diagram = DbInsightsModelDiagram.new
    diagram.process_classes models
    diagram.to_json
  end
  
  def self.build_connection_from_db_url db_url
    begin
      uri = URI.parse db_url
    rescue URI::InvalidURIError
      raise "Invalid DATABASE_URL"
    end
    connection = {
      :adapter => uri.scheme, :username => uri.user, :password => uri.password,
      :host => uri.host, :port => uri.port, :database => (uri.path || "").split("/")[1]
    }
    connection[:adapter] = 'postgresql' if connection[:adapter] == 'postgres'
    connection[:adapter] = 'mysql2' if connection[:adapter] == 'mysql'
    @@current_adapter = connection[:adapter]
    params = CGI.parse(uri.query || '')
    params.each {|k, v| connection[k] = v.first }
    connection
  end
  
  def self.postgresql?
    current_adapter == 'postgresql'
  end
  
  def self.mysql?
    current_adapter == 'mysql2'
  end
  
  def self.reset_current_db_url
    @@current_db_url = nil
  end

end
