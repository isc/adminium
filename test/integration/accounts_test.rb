require 'test_helper'

class AccountsTest < ActionDispatch::IntegrationTest
  test 'update account settings' do
    travel_to '2019-01-09 20:59'
    account = login
    FixtureFactory.new(:user, pseudo: 'Zoé', birthdate: '2017-08-02')
    visit resources_path(:users)
    assert_no_text 'less than a minute ago'
    assert_text 'August 02, 2017'
    visit edit_account_path
    new_db_url = "#{account.db_url}?plop=plip"
    fill_in 'Database URL', with: new_db_url
    click_button 'Update Account'
    assert_text 'Changes saved'
    assert has_field?('Database URL', with: new_db_url)
    assert has_field?('Per page', with: 25)
    fill_in 'Per page', with: 150
    select 'less than a minute ago'
    select '2019-01-09'
    click_on 'Update Account'
    assert_text 'Changes saved'
    assert has_field?('Per page', with: 150)
    assert has_select?('Datetime format', selected: 'less than a minute ago')
    fill_in 'Database URL', with: 'stable screenshot'
    save_screenshot 'account_settings'
    visit resources_path(:users)
    assert_text 'less than a minute ago'
    assert_text '2017-08-02'
  end
end
