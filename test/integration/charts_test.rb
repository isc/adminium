require 'test_helper'

class ChartsTest < ActionDispatch::IntegrationTest
  def setup
    FixtureFactory.clear_db
    login
  end

  test 'display default timechart then periodic grouping' do
    Timecop.travel '2018-10-21 21:00' do
      2.times { FixtureFactory.new(:user, created_at: Time.current.beginning_of_week) }
      FixtureFactory.new(:user, created_at: (Time.current.beginning_of_week + 2.days))
      display_chart :users, :created_at
      actual = evaluate_script 'data_for_graph.chart_data.datasets[0].values'
      expected = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0]
      assert_equal expected, actual
      select 'Day of week'
      assert_text 'Monday'
      assert_text 'Wednesday'
      actual = evaluate_script 'data_for_graph.chart_data.datasets[0].values'
      assert_equal [2, 1], actual
      save_screenshot 'time_chart_periodic_grouping.png'
    end
  end

  test 'display pie chart on boolean' do
    2.times { FixtureFactory.new(:user, admin: true) }
    FixtureFactory.new(:user, admin: false)
    FixtureFactory.new(:user, admin: nil)
    display_chart :users, :admin
    assert_text 'True: 2'
    assert_text 'Not set: 1'
    assert_text 'False: 1'
    save_screenshot 'percentage_chart_boolean.png'
  end

  test 'display pie chart on enums' do
    stub_resource_columns listing: %i(role)
    Resource::Base.any_instance.stubs(:enum_values_for)
      .returns 'admin' => {'label' => 'Chef'}, 'noob' => {'label' => 'Débutant'}
    6.times { FixtureFactory.new(:user, role: nil) }
    5.times { FixtureFactory.new(:user, role: 'noob') }
    4.times { FixtureFactory.new(:user, role: 'admin') }
    3.times { FixtureFactory.new(:user, role: 'new_role_1') }
    2.times { FixtureFactory.new(:user, role: 'new_role_2') }
    FixtureFactory.new(:user, role: 'new_role_3')
    display_chart :users, :role
    ['Not set: 6', 'Débutant: 5', 'Chef: 4', 'new_role_1: 3', 'new_role_2: 2', 'new_role_3: 1'].each do |slice|
      assert_text slice
    end
    save_screenshot 'percentage_chart_enum.png'
  end

  test 'display pie chart on foreign key with label column' do
    rob = FixtureFactory.new(:user, pseudo: 'Rob').factory
    bob = FixtureFactory.new(:user, pseudo: 'Bob').factory
    FixtureFactory.new(:comment, user_id: rob.id)
    2.times { FixtureFactory.new(:comment, user_id: bob.id) }
    Resource::Base.any_instance.stubs(:label_column).returns 'pseudo'
    display_chart :comments, :user_id
    assert_text 'Bob: 2'
    assert_text 'Rob: 1'
  end

  test 'display pie chart with where and grouping' do
    Timecop.travel '2017-01-10' do
      FixtureFactory.new(:user, admin: false, created_at: '2017-01-01')
      FixtureFactory.new(:user, admin: true, created_at: '2017-01-02')
      display_chart :users, :created_at
      find('rect[data-point-index="21"]').click
      assert_selector '.alert-warning', text: 'Where daily created_at is Jan 01'
      find('th[data-column-name="admin"]').hover
      find('i.time-chart').click
      assert_text 'False: 1'
      assert_no_text 'True:'
      # visit chart_resources_path(:users,
      #   column: 'admin', type: 'PieChart', where: {created_at: '2017-01-01'}, grouping: 'yearly')
      # json = 'data_for_graph = {"chart_data":[["False",1,false,"#777"],["True",1,true,"#07be25"]],"chart_type":"PieChart","column":"admin","grouping":"yearly"}'
      # assert_equal json, page.find('script', visible: false).text(:all)
    end
  end

  test 'display stat chart' do
    2.times { FixtureFactory.new(:user, kind: 5) }
    FixtureFactory.new(:user, kind: 10)
    FixtureFactory.new(:user, kind: nil)
    display_chart :users, :kind, svg: false
    ['Maximum 10', 'Average 6.67', 'Median 5', 'Minimum 5', 'Sum 20', 'Count 3', 'Number of distinct values 2']
      .each do |metric|
        assert_text metric
      end
    save_screenshot 'stat_chart.png'
  end

  private

  def display_chart table, column, svg: true
    visit resources_path(table)
    find("th[data-column-name=\"#{column}\"]").hover
    find('i.time-chart').click
    assert_selector 'svg.frappe-chart.chart' if svg
  end
end
