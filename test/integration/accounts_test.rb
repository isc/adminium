require 'test_helper'

class AccountsTest < ActionDispatch::IntegrationTest
  test 'pet project limitation' do
    login create(:account, plan: Account::Plan::PET_PROJECT)
    visit dashboard_path
    find('a', text: 'Close').click
    click_link 'roles_users' # table number 6 is off limit
    assert_selector '.modal', text: 'This table is not accessible'
    save_screenshot 'pet_project_limitation_modal.png'
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
    assert has_field?('Database URL', with: new_db_url)
    save_screenshot 'account_settings.png'
  end
end
