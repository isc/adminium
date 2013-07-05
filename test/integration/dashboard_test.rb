require 'test_helper'

class DashboardTest < ActionDispatch::IntegrationTest

  test "view dashboard" do
    Timecop.freeze(Date.today) do
      login
      visit dashboard_path
      assert page.has_content?('Database size')
      assert page.has_content?('Welcome On Board')
      visit dashboard_path
      assert page.has_no_content?('Welcome On Board')
      assert page.has_no_content?('Basic Search')
      Timecop.travel 2.days.from_now
      visit dashboard_path
      assert page.has_content?('Basic Search')
    end
    Timecop.return
  end
  
  test "view dashboard with widgets" do
    account = create(:account)
    create :time_chart_widget, account: account
    create :table_widget, account: account
    login account
    visit dashboard_path
    assert page.has_css?('li.widget', count: 2)
  end

end