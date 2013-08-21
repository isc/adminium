require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  
  def test_show_user_apps
    heroku_api = Heroku::API.new(api_key: '123', mock: true)
    app1 = heroku_api.post_app(name: 'app-with-addon-installed').data[:body]
    Account.delete_all
    Factory :account, heroku_id: "app#{app1['id']}@heroku.com", name: app1['name']
    heroku_api.post_app(name: 'app-with-addon-not-installed').data[:body]
    user = Factory :user, name: nil, email: 'jessy@cluscrive.fr'
    session[:user] = user.id
    session[:heroku_access_token] = '123'
    get :show
    assert_response :success
    assert_equal ['app-with-addon-installed'], assigns[:installed_apps].map(&:name)
    assert_equal ['app-with-addon-not-installed'], assigns[:apps].map{|app| app['name']}
  end
end