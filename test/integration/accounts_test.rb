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
    FixtureFactory.new(:user, pseudo: 'Zoé')
    visit resources_path(:users)
    assert_no_text 'less than a minute ago'
    visit edit_account_path
    new_db_url = "#{account.db_url}?plop=plip"
    fill_in 'Database URL', with: new_db_url
    click_button 'Update Account'
    assert_text 'Changes saved'
    assert has_field?('Database URL', with: new_db_url)
    fill_in 'Database URL', with: 'stable screenshot'
    save_screenshot 'account_settings.png'
    click_on 'Display settings'
    assert has_field?('Per page', with: 25)
    fill_in 'Per page', with: 150
    select 'less than a minute ago'
    click_on 'Save settings'
    assert_text 'Changes saved'
    click_on 'Display settings'
    assert has_field?('Per page', with: 150)
    assert has_select?('Datetime format', selected: 'less than a minute ago')
    visit resources_path(:users)
    assert_text 'less than a minute ago'
  end
end
