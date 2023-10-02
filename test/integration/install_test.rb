require 'test_helper'

class InstallTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test 'missing db url page' do
    login
    visit setup_database_connection_install_path
    assert_text 'Adminium has been successfully provisioned'
    save_screenshot 'setup_database_connection'
  end
end
