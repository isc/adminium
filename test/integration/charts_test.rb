require 'test_helper'

class ChartsTest < ActionDispatch::IntegrationTest
  def setup
    FixtureFactory.clear_db
    login
  end

  test 'display default timechart' do
    2.times { FixtureFactory.new(:user, created_at: 3.days.ago) }
    FixtureFactory.new(:user, created_at: 5.days.ago)
    visit chart_resources_path(:users, column: 'created_at', type: 'TimeChart')
    assert_match(/\[".*",1,.*\].*\[".*",2,".*"\]/, page.find('script', visible: false).text(:all))
  end

  test 'display timechart with periodic grouping' do
    2.times { FixtureFactory.new(:user, created_at: Time.current.beginning_of_week) }
    FixtureFactory.new(:user, created_at: (Time.current.beginning_of_week + 2.days))
    visit chart_resources_path(:users, column: 'created_at', grouping: 'dow', type: 'TimeChart')
    json = 'data_for_graph = {"chart_data":[["Monday",2,1.0],["Wednesday",1,3.0]],"chart_type":"TimeChart","column":"created_at","grouping":"dow"}'
    assert_equal json, page.find('script', visible: false).text(:all)
  end

  test 'display pie chart on boolean' do
    2.times { FixtureFactory.new(:user, admin: true) }
    FixtureFactory.new(:user, admin: false)
    FixtureFactory.new(:user, admin: nil)
    visit chart_resources_path(:users, column: 'admin', type: 'PieChart')
    json = 'data_for_graph = {"chart_data":[["True",2,true,"#07be25"],["Not set",1,null,"#DDD"],["False",1,false,"#777"]],"chart_type":"PieChart","column":"admin","grouping":"daily"}'
    assert_equal json, page.find('script', visible: false).text(:all)
  end

  test 'display pie chart on enums' do
    Resource::Base.any_instance.stubs(:enum_values_for).with('role')
      .returns 'admin' => {'label' => 'Chef'}, 'noob' => {'label' => 'Débutant'}
    FixtureFactory.new(:user, role: 'admin')
    FixtureFactory.new(:user, role: 'noob')
    FixtureFactory.new(:user, role: 'new_role_1')
    FixtureFactory.new(:user, role: 'new_role_2')
    FixtureFactory.new(:user, role: 'new_role_3')
    FixtureFactory.new(:user, role: nil)
    visit chart_resources_path(:users, column: 'role', type: 'PieChart')
    json = 'data_for_graph = {"chart_data":[["Not set",1,null,"#DDD"],["new_role_3",1,"new_role_3","#AAA"],["new_role_2",1,"new_role_2","#CCC"],["Débutant",1,"noob",null],["Chef",1,"admin",null],["new_role_1",1,"new_role_1","#AAA"]],"chart_type":"PieChart","column":"role","grouping":"daily"}'
    assert_equal json, page.find('script', visible: false).text(:all)
  end

  test 'display pie chart on foreign key with label column' do
    rob = FixtureFactory.new(:user, pseudo: 'Rob').factory
    bob = FixtureFactory.new(:user, pseudo: 'Bob').factory
    FixtureFactory.new(:comment, user_id: rob.id)
    2.times { FixtureFactory.new(:comment, user_id: bob.id) }
    Resource::Base.any_instance.stubs(:label_column).returns 'pseudo'
    visit chart_resources_path(:comments, column: 'user_id', type: 'PieChart')
    json = "data_for_graph = {\"chart_data\":[[\"Bob\",2,#{bob.id},\"#CCC\"],[\"Rob\",1,#{rob.id},\"#AAA\"]],\"chart_type\":\"PieChart\",\"column\":\"user_id\",\"grouping\":\"daily\"}"
    assert_equal json, page.find('script', visible: false).text(:all)
  end

  test 'display pie chart with where and grouping' do
    FixtureFactory.new(:user, admin: false, created_at: '2017-01-01')
    FixtureFactory.new(:user, admin: true, created_at: '2017-01-02')
    visit chart_resources_path(:users, column: 'admin', type: 'PieChart', where: {created_at: '2017-01-01'})
    json = 'data_for_graph = {"chart_data":[["False",1,false,"#777"]],"chart_type":"PieChart","column":"admin","grouping":"daily"}'
    assert_equal json, page.find('script', visible: false).text(:all)
    visit chart_resources_path(:users,
      column: 'admin', type: 'PieChart', where: {created_at: '2017-01-01'}, grouping: 'yearly')
    json = 'data_for_graph = {"chart_data":[["False",1,false,"#777"],["True",1,true,"#07be25"]],"chart_type":"PieChart","column":"admin","grouping":"yearly"}'
    assert_equal json, page.find('script', visible: false).text(:all)
  end

  test 'display stat chart' do
    2.times { FixtureFactory.new(:user, kind: 5) }
    FixtureFactory.new(:user, kind: 10)
    FixtureFactory.new(:user, kind: nil)
    visit chart_resources_path(:users, column: 'kind', type: 'StatChart')
    json = 'data_for_graph = {"chart_data":[["Maximum","10",10],["Average","6.67"],["Median","5"],["Minimum","5",5],["Sum","20"],["Count",3],["Number of distinct values",2]],"chart_type":"StatChart","column":"kind","grouping":"daily"}'
    assert_equal json, page.find('script', visible: false).text(:all)
  end
end
