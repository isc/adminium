require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  
  def test_show_user
    heroku_api = Heroku::API.new(api_key: '123', mock: true)
    app1 = heroku_api.post_app(name: 'app-with-addon-installed').data[:body]
    Account.delete_all
    Factory :account, heroku_id: "app#{app1['id']}@heroku.com", name: app1['name']
    heroku_api.post_app(name: 'app-with-addon-not-installed').data[:body]
    user = Factory :user, name: nil, email: 'jessy@cluscrive.fr', provider: 'heroku'
    session[:user] = user.id
    session[:heroku_access_token] = '123'
    get :show, format: :json
    assert_response :success
    assert_equal ['app-with-addon-installed'], assigns[:installed_apps].map(&:name)
    assert_equal ['app-with-addon-not-installed'], assigns[:apps].map{|app| app['name']}
  end
  
  def test_show_user_apps_with_just_an_account
    account = Factory :account
    session[:account] = account.id
    get :apps
    assert_response :success
  end
  
  def test_show_user_heroku_apps_with_a_user_and_no_account
    user = Factory :user, provider: 'heroku'
    session[:user] = user.id
    session[:heroku_access_token] = '123'
    get :apps
    assert_response :success
    total_apps= (assigns(:apps) + assigns(:installed_apps)).length
    assert_equal total_apps, user.reload.total_heroku_apps
  end
  
  def test_show_user_apps_with_a_user_and_no_account
    collaborator = Factory :collaborator, account: Factory(:account, plan: 'enterprise')
    session[:user] = collaborator.user_id
    session[:account] = collaborator.account_id
    get :apps
    assert_response :success
  end
  
end