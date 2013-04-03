ENV["RAILS_ENV"] = "test"
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
    page.set_rack_session :account => account.id
    account
  end

end

class FixtureFactory

  def initialize(name, options = {})
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['fixture']
    @factory = Factory "#{name}_from_test", options
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
  end

  def save!
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['fixture']
    @factory.save!
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
    @factory
  end


  def self.clear_db
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['fixture']
    %w(users comments).each do |table_name|
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
    end
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
  end

end