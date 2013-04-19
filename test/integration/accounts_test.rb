# encoding: UTF-8
require 'test_helper'

class AccountsTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
  end
  
  test "pet project limitation" do
    login Factory(:account, plan: Account::Plan::PET_PROJECT)
    visit dashboard_path
    click_link 'roles_users' # table number 6 is off limit
    assert_equal dashboard_path, page.current_path
    assert page.has_content?('to the startup plan ($10 per month)')
  end

end
