ENV['RAILS_ENV'] = 'test'
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

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test_database_schema.rb'
require 'capybara/rails'
require 'mocha/setup'
require 'rack_session_access/capybara'

DatabaseCleaner.strategy = :truncation

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  self.use_transactional_tests = false
  teardown do
    REDIS.flushdb
    Rails.cache.clear
    ObjectSpace.each_object(Generic, &:cleanup)
    DatabaseCleaner.clean
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  def login account = nil
    account ||= create :account
    page.set_rack_session account: account.id
    account
  end

  def logout
    page.set_rack_session account: nil
    page.set_rack_session user: nil
  end

  teardown do
    logout
  end
end

class FixtureFactory
  attr_reader :factory

  def initialize(name, options = {})
    self.class.with_fixture_connection { @factory = FactoryGirl.create "#{name}_from_test", options }
  end

  def save!
    self.class.with_fixture_connection { @factory.save! }
    @factory
  end

  def self.clear_db
    with_fixture_connection do
      %w(users comments groups roles roles_users documents uploaded_files).each do |table_name|
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
      end
    end
  end

  def reload!
    self.class.with_fixture_connection { factory.reload }
  end

  def self.with_fixture_connection
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations["fixture-#{TEST_ADAPTER}"]
    yield
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
  end
end
