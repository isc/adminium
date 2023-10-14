require 'test_helper'

class SetupTest < ActionDispatch::IntegrationTest
  test 'sign up and setup account' do
    options = { protocol: :ctap2, transport: :internal, resident_key: false, user_verification: true, user_verified: true }
    page.driver.browser.add_virtual_authenticator ::Selenium::WebDriver::VirtualAuthenticatorOptions.new(options)
    visit root_path
    click_on 'Sign up'
    fill_in 'Email', with: 'joe@mail.com'
    click_on 'Sign up'
    fill_in 'Database name', with: 'adminium-fixture'
    click_on 'Create'
    fill_in 'postgresql://user:password@host/database', with: Rails.configuration.test_database_conn_spec
    click_on 'Connect'
    assert_text 'Welcome on board'
    click_on 'Close'
    click_on 'comments'
    assert_text 'No records were found.'
    click_on 'Signed in as joe@mail.com'
    click_on 'Sign out'
    assert_text 'Signed out!'
    click_on 'Sign in'
    fill_in 'Email', with: 'joe@mail.fr'
    within('form') { click_on 'Sign in' }
    assert_text "User doesn't exist"
    fill_in 'Email', with: 'joe@mail.com'
    within('form') { click_on 'Sign in' }
    assert_text 'Dashboard'
    assert has_link?('documents')
  end
end
