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

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'test_database_schema.rb'
require 'capybara/rails'
require 'capybara-screenshot/minitest'
require 'mocha/setup'
require 'rack_session_access/capybara'
require 'test_failures_reporter'

DatabaseCleaner.strategy = :truncation
Capybara.default_driver = ENV['DISABLE_HEADLESS'] ? :selenium_chrome : :selenium_chrome_headless
Capybara.server = :puma, { Silent: true }

Capybara::Screenshot.register_filename_prefix_formatter(:minitest) do |test_case|
  test_name = test_case.respond_to?(:name) ? test_case.name : test_case.__name__
  "failed-test-screenshot-#{test_name}"
end

reporters = [Minitest::Reporters::DefaultReporter.new]
reporters << TestFailuresReporter.new if ENV['REMOTE_REPORTER_URL'].present?
Minitest::Reporters.use! reporters

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  self.use_transactional_tests = false

  setup do
    FixtureFactory.clear_db
  end

  teardown do
    REDIS.flushdb
    Rails.cache.clear
    ObjectSpace.each_object(Generic, &:cleanup)
    DatabaseCleaner.clean
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Screenshot::MiniTestPlugin

  def login account = nil
    account ||= create :account
    page.set_rack_session account: account.id
    account
  end

  def click_link_with_title title
    find("a[data-original-title=\"#{title}\"]").click
  end

  def open_accordion pane_label, selector:, text:
    click_link pane_label while all(selector, text: text, minimum: 0).size.zero?
  end

  def stub_resource_columns value
    %i(serialized show form listing search).each do |key|
      value[key] = [] unless value.key? key
    end
    Resource.any_instance.stubs(:columns).returns value
  end

  teardown do
    Capybara.reset!
  end
end

class FixtureFactory
  attr_reader :factory

  def initialize(name, options = {})
    self.class.with_fixture_connection { @factory = FactoryBot.create "#{name}_from_test", options }
  end

  def save!
    self.class.with_fixture_connection { @factory.save! }
    @factory
  end

  def self.clear_db
    with_fixture_connection do
      %w(users comments groups roles roles_users documents uploaded_files).each do |table_name|
        ActiveRecord::Base.connection.execute "TRUNCATE TABLE #{table_name} RESTART IDENTITY"
      end
      ActiveRecord::Base.connection.execute 'select pg_stat_reset()'
    end
  end

  def reload!
    self.class.with_fixture_connection { factory.reload }
  end

  def self.with_fixture_connection
    ActiveRecord::Base.establish_connection Rails.configuration.test_database_conn_spec
    yield
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
  end
end
