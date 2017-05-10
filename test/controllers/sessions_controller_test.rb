require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def test_register_via_heroku
    User.delete_all
    request.env['omniauth.auth'] = {'credentials' => {'token' => '123'}}
    assert_difference 'User.count' do
      get :create_from_heroku
    end
    assert_redirected_to user_path
    user = User.last
    assert_equal 'heroku', user.provider
    assert_nil user.name
    assert_equal 'user@example.com', user.email
    assert_equal '123456@users.heroku.com', user.uid
  end

  def test_should_fill_db_url_if_account_logged
    app_name = 'my-test-app-1'
    db_url = 'postgres://mm:4vb9@ec2-54-225-96-191.compute-1.amazonaws.com:5432/d3c'
    data = heroku_api.post_app(name: app_name).data[:body]
    heroku_api.post_collaborator app_name, 'jean@michel.com'
    app_id = "app#{data['id']}@heroku.com"
    heroku_api.put_config_vars(app_name, 'DATABASE_URL' => db_url)
    account = create :account, heroku_id: app_id, db_url: nil, name: nil, owner_email: nil
    session[:account] = account.id
    request.env['omniauth.auth'] = {'credentials' => {'token' => '123'}}
    get :create_from_heroku
    heroku_api.delete_app app_name
    assert_redirected_to dashboard_path
    assert_equal 'oauth', account.reload.db_url_setup_method
    assert_equal db_url, account.db_url
    assert_equal app_name, account.name
    assert account.app_profile.app_infos
    assert account.app_profile.addons_infos
    assert_equal 2, account.total_heroku_collaborators
    assert_equal 'email@example.com', account.owner_email
  end

  def test_login_heroku_app
    app_name = 'my-test-app-2'
    app = heroku_api.post_app(name: app_name).data[:body]
    session[:heroku_access_token] = '123'
    account = create :account, heroku_id: "app#{app['id']}@heroku.com", name: app_name
    user = create :user, provider: 'heroku'
    session[:user] = user.id
    assert_difference 'SignOn.count' do
      get :login_heroku_app, id: app['id']
      heroku_api.delete_app app_name
      assert_redirected_to root_url
      assert_equal account.id, session[:account]
      assert_nil session[:collaborator]
    end
  end

  private

  def heroku_api
    @heroku_api ||= Heroku::API.new(api_key: '123', mock: true)
  end
end
