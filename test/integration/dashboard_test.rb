require 'test_helper'

class DashboardTest < ActionDispatch::IntegrationTest
  setup do
    @account = login
  end

  test 'view dashboard' do
    visit dashboard_path
    assert_text 'Welcome on board'
    save_screenshot 'welcome_modal'
    click_on 'Close'
    assert_text 'Database size'
    click_link 'pg_stat_activity'
    assert_text 'Pid'
    visit dashboard_path
    assert_no_text 'Welcome on board'
    assert_no_text 'Basic Search'
    travel 2.days
    visit dashboard_path
    assert_selector '.modal-title', text: 'Basic Search'
  end

  test 'view dashboard with widgets' do
    create :time_chart_widget, account: @account
    create :table_widget, account: @account
    visit dashboard_path
    assert_selector '.widget', count: 2
    click_on 'Close'
    assert_no_selector '.modal'
    assert_selector '.alert', text: 'No data to chart'
    save_screenshot 'dashboard_with_widget'
  end

  test 'catching database url errors' do
    @account.db_url += 'plop'
    @account.save validate: false
    visit dashboard_path
    assert_text 'There was a database error'
  end

  test 'show database settings' do
    visit dashboard_path
    click_on 'Close'
    click_on 'Database settings'
    assert_text 'application_name'
    assert_text 'autovacuum'
    fill_in 'Filter by name', with: 'vacuum'
    click_on 'Filter'
    assert_text 'autovacuum'
    assert_no_text 'application_name'
  end
end
