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
require 'mocha/minitest'
require 'rack_session_access/capybara'

DatabaseCleaner.strategy = :truncation

chrome_bin = ENV.fetch('GOOGLE_CHROME_SHIM', nil)
Selenium::WebDriver::Chrome.path = chrome_bin if chrome_bin

Capybara.register_driver :heroku_compatible_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('headless') unless ENV['DISABLE_HEADLESS']
  options.add_argument('no-sandbox')
  options.add_argument('disable-dev-shm-usage')
  options.add_preference(:download, { default_directory: Rails.root.join('tmp') })
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara::Screenshot.register_driver(:heroku_compatible_chrome) do |driver, path|
  driver.browser.save_screenshot path
end


Capybara.default_driver = :heroku_compatible_chrome
Capybara.server = :puma, { Silent: true }
Capybara.server_host = 'localhost'

Capybara::Screenshot.register_filename_prefix_formatter(:minitest) do |test_case|
  test_name = test_case.respond_to?(:name) ? test_case.name : test_case.__name__
  "failed-test-screenshot-#{test_name}"
end

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  self.use_transactional_tests = false

  setup do
    FixtureFactory.clear_db
  end

  teardown do
    Rails.cache.clear
    ObjectSpace.each_object(Generic, &:cleanup)
    DatabaseCleaner.clean
  end

  def setup_resource_columns account, table, value
    TableConfiguration.find_or_create_by(account_id: account.id, table: table).update column_selection: value
  end
end

class ActionController::TestCase
  def create_account_and_login
    collaborator = create :collaborator
    account = collaborator.account
    session[:account_id] = account.id
    session[:user_id] = collaborator.user_id
    session[:collaborator_id] = collaborator.id
    account
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Screenshot::MiniTestPlugin

  setup do
    FactoryBot.rewind_sequences # in order to have stable screenshots
  end

  def login
    collaborator = create :collaborator
    page.set_rack_session account_id: collaborator.account_id, collaborator_id: collaborator.id, user_id: collaborator.user_id
    collaborator.account
  end

  def click_link_with_title title
    find("a[data-original-title=\"#{title}\"]").click
  end

  def open_accordion pane_label, selector:, text:
    click_link pane_label while all(selector, text: text, minimum: 0).size.zero?
    assert_no_selector '.collapsing'
  end

  def save_screenshot name
    assert_no_selector '.tooltip, .collapsing'
    super "#{name}.png"
  end

  def downloaded_file file_path
    Timeout.timeout(5) do
      sleep 0.1
      File.read(file_path)
    rescue Errno::ENOENT
      retry
    end
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
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations.find_db_config('test')
  end
end
