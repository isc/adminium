require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def test_register_via_heroku
    setup_omniauth_env
    assert_difference 'User.count' do
      get :create_from_heroku
    end
    assert_redirected_to user_path
    user = User.last
    assert_equal 'heroku', user.provider
    assert_equal 'User Example', user.name
    assert_equal 'user@example.com', user.email
    assert_equal '123456@users.heroku.com', user.uid
  end

  def test_should_fill_db_url_if_account_logged
    app_name = 'my-test-app-1'
    db_url = 'postgres://u:p@h/d'
    addon = stub(info: {'app' => {'name' => app_name}})
    app = stub(info: {'owner' => {'email' => 'email@example.com'}})
    config_var = stub(info: {'DATABASE_URL' => db_url})
    SessionsController.any_instance.stubs(:heroku_api).returns stub(addon: addon, app: app, config_var: config_var)
    account = create :account, heroku_uuid: '37', db_url: nil, name: nil, owner_email: nil
    session[:account] = account.id
    setup_omniauth_env
    get :create_from_heroku
    assert_redirected_to dashboard_path
    assert_equal 'oauth', account.reload.db_url_setup_method
    assert_equal db_url, account.db_url
    assert_equal app_name, account.name
    assert_equal 'email@example.com', account.owner_email
  end

  def test_login_heroku_app
    SessionsController.any_instance.stubs(:heroku_api).returns stub(addon: stub(list: [{'id' => '37'}]))
    app_name = 'my-test-app-2'
    account = create :account, heroku_uuid: '37', name: app_name
    user = create :user, provider: 'heroku'
    session[:user] = user.id
    assert_difference 'SignOn.count' do
      get :login_heroku_app, params: {id: '37'}
      assert_redirected_to root_url
      assert_equal account.id, session[:account]
      assert_nil session[:collaborator]
    end
  end

  private

  def setup_omniauth_env
    request.env['omniauth.auth'] = {
      'credentials' => {'token' => '123'},
      'extra' => {'id' => '123456@users.heroku.com', 'email' => 'user@example.com', 'name' => 'User Example'}
    }
  end
end
