require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def test_show_user
    Search.delete_all
    Account.delete_all
    app_list = [
      {'id' => '123', 'name' => 'app-with-addon-installed'}, {'id' => '456', 'name' => 'app-with-addon-not-installed'}
    ]
    UsersController.any_instance.stubs(:heroku_api).returns stub(app: stub(list: app_list))
    create :account, heroku_id: '123', name: 'app-with-addon-installed'
    user = create :user, provider: 'heroku'
    session[:user] = user.id
    session[:heroku_access_token] = '123'
    get :show, params: {format: :json}
    assert_response :success
    assert_equal ['app-with-addon-installed'], assigns[:installed_apps].map(&:name)
    assert assigns[:apps].map {|app| app['name']}.include?('app-with-addon-not-installed')
  end

  def test_show_user_apps_with_just_an_account
    account = create :account
    session[:account] = account.id
    get :apps
    assert_response :success
  end

  def test_show_user_heroku_apps_with_a_user_and_no_account
    UsersController.any_instance.stubs(:heroku_api).returns stub(app: stub(list: []))
    user = create :user, provider: 'heroku'
    session[:user] = user.id
    session[:heroku_access_token] = '123'
    get :apps
    assert_response :success
    total_apps = (assigns(:apps) + assigns(:installed_apps)).length
    assert_equal total_apps, user.reload.total_heroku_apps
  end

  def test_show_user_apps_with_a_user_and_no_account
    collaborator = create :collaborator, account: create(:account, plan: 'enterprise')
    session[:user] = collaborator.user_id
    session[:account] = collaborator.account_id
    get :apps
    assert_response :success
  end
end
