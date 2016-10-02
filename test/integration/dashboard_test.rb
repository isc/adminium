require 'test_helper'

class DashboardTest < ActionDispatch::IntegrationTest
  test 'view dashboard' do
    login
    visit dashboard_path
    assert_text 'Database size'
    assert_text 'Welcome On Board'
    visit dashboard_path
    assert_no_text 'Welcome On Board'
    assert_no_text 'Basic Search'
    Timecop.travel 2.days.from_now do
      visit dashboard_path
      assert_text 'Basic Search'
    end
  end

  test 'view dashboard with widgets' do
    account = create :account
    create :time_chart_widget, account: account
    create :table_widget, account: account
    login account
    visit dashboard_path
    assert_selector '.widget', count: 2
  end

  test 'catching database url errors' do
    account = create :account
    login account
    account.db_url += 'plop'
    account.save validate: false
    visit dashboard_path
    assert_text 'There was a database error'
  end
end
