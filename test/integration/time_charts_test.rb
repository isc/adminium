# encoding: UTF-8
require 'test_helper'

class TimeChartsTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
    login
  end

  test "display default timechart" do
    2.times { FixtureFactory.new(:user, created_at: 3.days.ago) }
    FixtureFactory.new(:user, created_at: 5.days.ago)
    visit time_chart_resources_path(:users, column: 'created_at')
    assert_match(/\[".*",1,.*\].*\[".*",2,".*"\]/, page.find('script[type="text/javascript"]', visible: false).text(:all))
  end
  
  test "display timechart with periodic grouping" do
    2.times { FixtureFactory.new(:user, created_at: Time.now.beginning_of_week) }
    FixtureFactory.new(:user, created_at: (Time.now.beginning_of_week + 2.days))
    visit time_chart_resources_path(:users, column: 'created_at', grouping: 'dow')
    # FIXME because of timezones we end up with Sunday and Tuesday
    assert_equal 'chart_data = [["Sunday",2,0.0],["Tuesday",1,2.0]]', page.find('script[type="text/javascript"]', visible: false).text(:all)
  end
  
end
