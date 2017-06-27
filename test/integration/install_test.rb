require 'test_helper'

class InstallsTest < ActionDispatch::IntegrationTest
  test 'missing db url page' do
    login
    visit setup_database_connection_install_path
  end

  test 'get some collaborators' do
    account = create :account, name: 'tasty'
    login account
    heroku_api = Heroku::API.new(api_key: '123', mock: true)
    heroku_api.post_app(name: 'tasty')
    heroku_api.post_collaborator('tasty', 'j@m.com')
    page.set_rack_session user: create(:user, provider: 'heroku', email: 'j@m.com').id
    page.set_rack_session heroku_access_token: '123'
    visit invite_team_install_path
    assert_difference 'ActionMailer::Base.deliveries.length' do
      click_button 'Send a welcome email to the team'
      assert_no_text 'Installation steps'
      assert_text 'Dashboard'
    end
    mail = ActionMailer::Base.deliveries.last
    assert_equal 'jessy.bernal+should_not_be_receive@gmail.com', mail['to'].to_s
    assert_equal %w(email@example.com j@m.com), JSON.parse(mail['X-SMTPAPI'].to_s)['to']
    assert_text 'Dashboard'
  end
end
