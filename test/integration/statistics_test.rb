                                                                                                                                # encoding: UTF-8
require 'test_helper'

class StatititicsTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
    login
  end
  
  test "should add a statistic" do
    assert_difference 'Statistic.count' do
      visit dashboard_path
      visit dashboard_path
    end
    stat = Statistic.all.last
    assert_equal 2, stat.value
    assert_equal "dashboards#show", stat.action
  end
  
end
