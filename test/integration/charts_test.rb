require 'test_helper'

class ChartsTest < ActionDispatch::IntegrationTest
  def setup
    login
  end

  test 'display default timechart then periodic grouping' do
    Timecop.travel '2018-10-21 21:00' do
      2.times { FixtureFactory.new(:user, created_at: Time.current.beginning_of_week) }
      FixtureFactory.new(:user, created_at: (Time.current.beginning_of_week + 2.days))
      display_chart :users, :created_at
      actual = evaluate_script 'data_for_graph.chart_data'
      expected = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0]
      assert_equal expected, actual.map(&:second)
      select 'Day of week'
      assert_text 'Monday'
      assert_text 'Wednesday'
      actual = evaluate_script 'data_for_graph.chart_data'
      assert_equal [2, 1], actual.map(&:second)
      save_screenshot 'time_chart_periodic_grouping.png'
    end
  end

  test 'display pie chart on boolean' do
    2.times { FixtureFactory.new(:user, admin: true) }
    FixtureFactory.new(:user, admin: false)
    FixtureFactory.new(:user, admin: nil)
    display_chart :users, :admin
    expected = [['True', 2, true, '#07be25'], ['Not set', 1, nil, '#DDD'], ['False', 1, false, '#777']]
    actual = evaluate_script 'data_for_graph.chart_data'
    assert expected, actual
    save_screenshot 'percentage_chart_boolean.png'
  end

  test 'display pie chart on enums' do
    stub_resource_columns listing: %i(role)
    Resource.any_instance.stubs(:enum_values_for)
      .returns 'admin' => {'label' => 'Chef'}, 'noob' => {'label' => 'Débutant'}
    6.times { FixtureFactory.new(:user, role: nil) }
    5.times { FixtureFactory.new(:user, role: 'noob') }
    4.times { FixtureFactory.new(:user, role: 'admin') }
    3.times { FixtureFactory.new(:user, role: 'new_role_1') }
    2.times { FixtureFactory.new(:user, role: 'new_role_2') }
    FixtureFactory.new(:user, role: 'new_role_3')
    display_chart :users, :role
    actual = evaluate_script 'data_for_graph.chart_data'
    expected = [
      ['Not set', 6, nil, '#DDD'],
      ['Débutant', 5, 'noob', '#AAA'],
      ['Chef', 4, 'admin', '#CCC'],
      ['new_role_1', 3, 'new_role_1', '#AAA'],
      ['new_role_2', 2, 'new_role_2', '#CCC'],
      ['new_role_3', 1, 'new_role_3', '#AAA']
    ]
    assert_equal expected, actual
    save_screenshot 'percentage_chart_enum.png'
  end

  test 'display pie chart on foreign key with label column' do
    rob = FixtureFactory.new(:user, pseudo: 'Rob').factory
    bob = FixtureFactory.new(:user, pseudo: 'Bob').factory
    FixtureFactory.new(:comment, user_id: rob.id)
    2.times { FixtureFactory.new(:comment, user_id: bob.id) }
    Resource.any_instance.stubs(:label_column).returns 'pseudo'
    display_chart :comments, :user_id
    actual = evaluate_script 'data_for_graph.chart_data'
    assert_equal [['Bob', 2], ['Rob', 1]], (actual.map { |r| r[0..1] })
  end

  test 'display pie chart with where and grouping' do
    Timecop.travel '2017-01-10' do
      FixtureFactory.new(:user, admin: false, created_at: '2017-01-01')
      FixtureFactory.new(:user, admin: true, created_at: '2017-01-02')
      display_chart :users, :created_at
      first('rect[height="223"]').click
      assert_selector '.alert-warning', text: 'Where daily created_at is Jan 01'
      display_chart nil, :admin
      assert_text 'False'
      assert_text '100%'
      assert_no_text 'True'
      # visit chart_resources_path(:users,
      #   column: 'admin', type: 'PieChart', where: {created_at: '2017-01-01'}, grouping: 'yearly')
      # json = 'data_for_graph = {'chart_data':[['False',1,false,'#777'],['True',1,true,'#07be25']],'chart_type':'PieChart','column':'admin','grouping':'yearly'}'
      # assert_equal json, page.find('script', visible: false).text(:all)
    end
  end

  test 'display pie chart on enum from belongs_to association' do
    stub_resource_columns listing: %i(title user_id user_id.role)
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, role: :admin).factory.id)
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, role: :developer).factory.id)
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, role: :admin).factory.id)
    visit resources_path(:comments)
    find('th[data-column-name="role"]').hover
    find('i.column_settings').click
    click_link 'Enumerable data'
    check 'Check if this column represents a specific set of values'
    all('.enum_details_area input[type=text]', minimum: 4)[1].set 'Administrator'
    click_on 'Save settings'
    assert_text 'Administrator'
    display_chart nil, :role
    expected = [['Administrator', 2, 'admin', '#86b558'], ['developer', 1, 'developer', '#ffb650']]
    actual = evaluate_script 'data_for_graph.chart_data'
    assert_equal expected, actual
  end

  test 'display stat chart' do
    stub_resource_columns listing: %i(role kind)
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
    visit resources_path(table) if table
    find("th[data-column-name=\"#{column}\"] i.time-chart").click
    assert_selector '#chart_div svg' if svg
  end
end
