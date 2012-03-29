ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'fixtures/test_database_schema.rb'
require 'capybara/rails'

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
