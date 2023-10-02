require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def test_show_user_apps_with_just_an_account
    account = create :account
    session[:account] = account.id
    get :apps
    assert_response :success
  end

  def test_show_user_apps_with_a_user_and_no_account
    collaborator = create :collaborator, account: create(:account, plan: 'enterprise')
    session[:user] = collaborator.user_id
    session[:account] = collaborator.account_id
    get :apps
    assert_response :success
  end
end
