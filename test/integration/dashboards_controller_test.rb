require 'test_helper'

class DashboardTest < ActionDispatch::IntegrationTest
  
  test "view dashboard" do
    login
    visit dashboard_path
    assert page.has_content?('Database size')
  end
  
end