require 'test_helper'

class InstallsTest < ActionDispatch::IntegrationTest

  test "missing db url page" do
    login
    visit setup_database_connection_install_path
  end
  
  test "get some collaborators" do
    account = create :account, name: 'tasty'
    login account
    heroku_api = Heroku::API.new(api_key: '123', mock: true)
    data = heroku_api.post_app(name: 'tasty').data[:body]
    heroku_api.post_collaborator('tasty', 'j@m.com')
    page.set_rack_session user: create(:user, provider: 'heroku', email: 'j@m.com').id
    page.set_rack_session heroku_access_token: '123'
    visit invite_team_install_path
    assert_difference "ActionMailer::Base.deliveries.length", 2 do
      click_button 'Send a welcome email to the team'
    end
    assert page.has_content?('Dashboard')
  end
  
end