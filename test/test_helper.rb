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
require 'test_failures_reporter'

DatabaseCleaner.strategy = :truncation

chrome_bin = ENV.fetch('GOOGLE_CHROME_SHIM', nil)
Selenium::WebDriver::Chrome.path = chrome_bin if chrome_bin

DOWNLOAD_DIR = '/tmp/adminium-tests-download-dir'
FileUtils.mkdir_p DOWNLOAD_DIR

Capybara.register_driver :heroku_compatible_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('headless') unless ENV['DISABLE_HEADLESS']
  options.add_argument('no-sandbox')
  options.add_argument('disable-dev-shm-usage')
  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  # Setting the downloadPath through a profile doesn't work at the moment when in headless mode
  # Workaround found here:
  # https://stackoverflow.com/questions/48810757/setting-default-download-directory-and-headless-chrome
  bridge = driver.browser.send(:bridge)
  bridge.http.call(:post, "/session/#{bridge.session_id}/chromium/send_command", cmd: 'Page.setDownloadBehavior',
    params: { behavior: 'allow', downloadPath: DOWNLOAD_DIR })
  driver
end

Capybara.default_driver = :heroku_compatible_chrome
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
    assert_no_selector '.collapsing'
  end

  def stub_resource_columns value
    %i(serialized show form listing search).each do |key|
      value[key] = [] unless value.key? key
    end
    Resource.any_instance.stubs(:columns).returns value
  end

  def save_screenshot name
    assert_no_selector '.tooltip, .collapsing'
    super "#{name}.png"
  end

  def clear_download_dir
    Dir.children(DOWNLOAD_DIR).each { |entry| File.unlink("#{DOWNLOAD_DIR}/#{entry}") }
  end

  def assert_downloaded_file filename, expected_content = nil
    downloaded_file = File.expand_path(filename, DOWNLOAD_DIR)
    actual_content = File.open(downloaded_file, &:read)
    if expected_content
      assert_equal expected_content, actual_content
    else
      yield actual_content
    end
  rescue Errno::ENOENT
    sleep 0.4
    retry
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
