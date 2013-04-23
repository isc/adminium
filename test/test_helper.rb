ENV["RAILS_ENV"] = "test"
if ENV['COVER']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
    add_filter '/config/'
    add_group 'Controllers', 'app/controllers'
    add_group 'Models', 'app/models'
    add_group 'Helpers', 'app/helpers'
  end
end

TEST_ADAPTER = ENV['adapter'] || ENV['ADAPTER'] || 'postgres'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'fixtures/test_database_schema.rb'
require 'capybara/rails'
require 'mocha/setup'
require 'rack_session_access/capybara'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = false
  teardown do
    REDIS.flushdb
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  def login account = nil
    account ||= Factory :account
    page.set_rack_session account: account.id
    account
  end
  
  def logout
    page.set_rack_session account: nil
  end
  
  teardown do
    logout
  end

end

class FixtureFactory
  
  attr_reader :factory
  
  def initialize(name, options = {})
    self.class.with_fixture_connection { @factory = Factory "#{name}_from_test", options }
  end

  def save!
    self.class.with_fixture_connection { @factory.save! }
    @factory
  end

  def self.clear_db
    with_fixture_connection do
      %w(users comments).each do |table_name|
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
      end
    end
  end
  
  def reload!
    self.class.with_fixture_connection { factory.reload }
  end
  
  def self.with_fixture_connection
    adapter = ENV['adapter'] || 'mysql'
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations["fixture-#{TEST_ADAPTER}"]
    yield
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
  end

end