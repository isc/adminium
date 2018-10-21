require 'test_helper'

class AccountsTest < ActionDispatch::IntegrationTest
  def setup
    FixtureFactory.clear_db
  end

  test 'pet project limitation' do
    login create(:account, plan: Account::Plan::PET_PROJECT)
    visit dashboard_path
    find('a', text: 'Close').click
    click_link 'roles_users' # table number 6 is off limit
    assert_selector '.modal', text: 'This table is not accessible'
    visit resources_path(:roles_users)
    assert_equal dashboard_path, current_path
    assert_text 'to the startup plan ($10 per month)'
  end

  test 'update account settings' do
    account = login
    visit edit_account_path
    new_db_url = "#{account.db_url}?plop=plip"
    fill_in 'Database URL', with: new_db_url
    click_button 'Update Account'
    assert_equal new_db_url, find_field('Database URL').value
  end
end
