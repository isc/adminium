# encoding: UTF-8
require 'test_helper'

class ChartsTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
    login
  end

  test "display default timechart" do
    2.times { FixtureFactory.new(:user, created_at: 3.days.ago) }
    FixtureFactory.new(:user, created_at: 5.days.ago)
    visit chart_resources_path(:users, column: 'created_at', type: 'TimeChart')
    assert_match(/\[".*",1,.*\].*\[".*",2,".*"\]/, page.find('script[type="text/javascript"]', visible: false).text(:all))
  end
  
  test "display timechart with periodic grouping" do
    2.times { FixtureFactory.new(:user, created_at: Time.now.beginning_of_week) }
    FixtureFactory.new(:user, created_at: (Time.now.beginning_of_week + 2.days))
    visit chart_resources_path(:users, column: 'created_at', grouping: 'dow', type: 'TimeChart')
    # FIXME because of timezones we end up with Sunday and Tuesday
    json = "data_for_graph = {\"chart_data\":[[\"Sunday\",2,0.0],[\"Tuesday\",1,2.0]],\"chart_type\":\"TimeChart\"}"
    assert_equal json, page.find('script[type="text/javascript"]', visible: false).text(:all)
  end
  
  test "display piechart" do
    2.times { FixtureFactory.new(:user, admin: true) }
    FixtureFactory.new(:user, admin: false)
    FixtureFactory.new(:user, admin: nil)
    visit chart_resources_path(:users, column: 'admin', type: 'PieChart')
    # FIXME because of timezones we end up with Sunday and Tuesday
    json = "data_for_graph = {\"chart_data\":[[\"not set\",1,null,\"#DDD\"],[\"False\",1,false,\"#777\"],[\"True\",2,true,\"#07be25\"]],\"chart_type\":\"PieChart\"}"
    assert_equal json, page.find('script[type="text/javascript"]', visible: false).text(:all)
  end
  
  test "display stat chart" do
    2.times { FixtureFactory.new(:user, kind: 5) }
    FixtureFactory.new(:user, kind: 10)
    FixtureFactory.new(:user, kind: nil)
    visit chart_resources_path(:users, column: 'kind', type: 'StatChart')
    # FIXME because of timezones we end up with Sunday and Tuesday
    json = "data_for_graph = {\"chart_data\":[[\"Maximum\",\"10\",10],[\"Average\",\"6.67\"],[\"Median\",\"5\"],[\"Minimum\",\"5\",5],[\"Sum\",\"20\"],[\"Count\",3],[\"Number of distinct values\",2]],\"chart_type\":\"StatChart\"}"
    assert_equal json, page.find('script[type="text/javascript"]', visible: false).text(:all)
  end
  
end
