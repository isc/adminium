require 'test_helper'

class InstallTest < ActionDispatch::IntegrationTest
  test 'missing db url page' do
    login
    visit setup_database_connection_install_path
  end

  test 'get some collaborators' do
    account = create :account, name: 'tasty'
    login account
    collaborators = [{'user' => {'email' => 'j@m.com'}}]
    InstallsController.any_instance.stubs(:heroku_api).returns stub(collaborator: stub(list: collaborators))
    page.set_rack_session user: create(:user, provider: 'heroku', email: 'j@m.com').id
    visit invite_team_install_path
    assert_difference 'ActionMailer::Base.deliveries.length' do
      click_button 'Send a welcome email to the team'
      assert_no_text 'Installation steps'
      assert_text 'Dashboard'
    end
    mail = ActionMailer::Base.deliveries.last
    assert_equal 'j@m.com', mail['to'].to_s
    assert_text 'Dashboard'
  end
end
