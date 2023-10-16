require 'test_helper'

class SetupTest < ActionDispatch::IntegrationTest
  test 'sign up and setup account' do
    add_virtual_authenticator
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
    using_session 'bob' do
      add_virtual_authenticator
      visit root_path
      click_on 'Sign up'
      fill_in 'Email', with: 'bob@mail.com'
      click_on 'Sign up'
      assert_text "You don't have access to any account"
    end
    click_on 'Signed in as joe@mail.com'
    click_on 'Collaborators'
    fill_in 'Email', with: 'bob@mail.com'
    choose 'Yes'
    click_on 'Add a collaborator'
    invite_url = build_last_invite_url
    assert_text invite_url
    using_session 'bob' do
      visit invite_url
      assert_text 'Dashboard'
      assert has_link?('documents')
      click_on 'Signed in as bob@mail.com'
      click_on 'Collaborators'
      fill_in 'Email', with: 'jack@mail.fr'
      choose 'Yes'
      click_on 'Add a collaborator'
      invite_url = build_last_invite_url
      assert_text invite_url
    end
    using_session 'jack' do
      add_virtual_authenticator
      visit invite_url
      click_link 'or Sign up'
      fill_in 'Email', with: 'joe@mail.com'
      click_on 'Sign up'
      assert_text 'Email has already been taken'
      fill_in 'Email', with: 'jack@mail.com'
      click_on 'Sign up'
      assert_text 'Dashboard'
      assert has_link?('documents')
    end
  end

  def add_virtual_authenticator
    options = { protocol: :ctap2, transport: :internal, resident_key: false, user_verification: true, user_verified: true }
    page.driver.browser.add_virtual_authenticator ::Selenium::WebDriver::VirtualAuthenticatorOptions.new(options)
  end

  def build_last_invite_url
    "#{Capybara.current_session.server.base_url}/dashboard?collaborator_token=#{Collaborator.last.token}"
  end
end
