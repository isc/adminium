require 'test_helper'

class InstallTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test 'missing db url page' do
    account = login
    account.update! db_url: nil
    visit dashboard_path
    assert_text 'Connecting to your database'
    save_screenshot 'setup_database_connection'
  end
end
