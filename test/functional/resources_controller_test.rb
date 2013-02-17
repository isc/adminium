require 'test_helper'

class ResourcesControllerTest < ActionController::TestCase

  def setup
    @account = Factory :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    ['Michel', 'Martin', nil].each_with_index do |pseudo, index|
      FixtureFactory.new :user, :pseudo => pseudo, :admin => false, :age => (17 + index), :activated_at => (2 * (index - 1)).week.ago
    end
    FixtureFactory.new :user, :pseudo => 'Loulou', :last_name => '', :admin => true, :age => 18, :activated_at => 1.hour.ago
  end

  def teardown
    assert_response :success
  end

  def test_asearch
    generic = Generic.new @account
    @settings = generic.table('users').settings
    @expectations = {}

    add_filter_to_test 'null_pseudo', [nil], [{"column" => 'pseudo', "type" => "string", "operator"=>"null"}]
    add_filter_to_test 'not_null_pseudo', ['Loulou', 'Martin', 'Michel'], [{"column" => 'pseudo', "type" => "string", "operator"=>"not_null"}]

    add_filter_to_test 'boolean_true', ['Loulou'], [{"column" => 'admin', "type" => "boolean", "operator"=>"is_true"}]
    add_filter_to_test 'boolean_false', ['Martin', 'Michel', nil], [{"column" => 'admin', "type" => "boolean", "operator"=>"is_false"}]

    add_filter_to_test 'integer_gt', [nil], [{"column" => 'age', "type" => "integer", "operator"=>">", "operand" => "18"}]
    add_filter_to_test 'integer_gte', ['Loulou', 'Martin', nil], [{"column" => 'age', "type" => "integer", "operator"=>">=", "operand" => "18"}]
    add_filter_to_test 'integer_lt', ['Michel'], [{"column" => 'age', "type" => "integer", "operator"=>"<", "operand" => "18"}]
    add_filter_to_test 'integer_lte', ['Loulou', 'Martin', 'Michel'], [{"column" => 'age', "type" => "integer", "operator"=>"<=", "operand" => "18"}]
    add_filter_to_test 'integer_eq', ['Loulou', 'Martin'], [{"column" => 'age', "type" => "integer", "operator"=>"=", "operand" => "18"}]
    add_filter_to_test 'integer_not_eq', ['Michel', nil], [{"column" => 'age', "type" => "integer", "operator"=>"!=", "operand" => "18"}]
    add_filter_to_test 'integer_in', ['Michel', nil], [{"column" => 'age', "type" => "datetime", "operator"=>"IN", "operand" => "17, 19"}]

    add_filter_to_test 'string_like', ['Michel'], [{"column" => 'pseudo', "type" => "integer", "operator"=>"like", "operand" => "iche"}]
    add_filter_to_test 'string_starts_with', ['Martin', 'Michel'], [{"column" => 'pseudo', "type" => "integer", "operator"=>"starts_with", "operand" => "M"}]
    add_filter_to_test 'string_ends_with', ['Martin'], [{"column" => 'pseudo', "type" => "integer", "operator"=>"ends_with", "operand" => "tin"}]
    add_filter_to_test 'string_not_like', ['Loulou', 'Martin'], [{"column" => 'pseudo', "type" => "integer", "operator"=>"not_like", "operand" => "iche"}]

    add_filter_to_test 'date_today', ['Loulou', 'Martin'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"today", "operand" => ""}]
    add_filter_to_test 'date_yesterday', [], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"yesterday", "operand" => ""}]
    add_filter_to_test 'date_this_week', [], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"this_week", "operand" => ""}]
    add_filter_to_test 'date_last_week', [], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"last_week", "operand" => ""}]
    add_filter_to_test 'date_on', ['Loulou', 'Martin'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"on", "operand" => 1.hour.ago}]
    add_filter_to_test 'date_before', ['Michel'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"before", "operand" => 1.hour.ago}]
    add_filter_to_test 'date_after', [nil], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"after", "operand" => 1.hour.ago}]

    add_filter_to_test 'string_blank', ["Loulou", "Martin", "Michel", nil], [{"column" => 'last_name', "type" => "string", "operator"=>"blank"}]
    add_filter_to_test 'string_present', [], [{"column" => 'last_name', "type" => "string", "operator"=>"present"}]

    add_filter_to_test 'and_grouping', ['Loulou'], [{"column" => 'pseudo', "type" => "string", "operator"=>"not_null"}, {"column" => 'admin', "type" => "boolean", "operator"=>"is_true"}]
    add_filter_to_test 'or_grouping', ['Loulou', 'Michel'], [{"column" => 'age', "type" => "integer", "operator"=>"=", 'operand' => 17}, {"column" => 'admin', "type" => "boolean", "operator"=>"is_true", 'grouping' => 'or'}]

    @settings.save

    @expectations.each do |filter_name, expected_result|
      assert_asearch filter_name, expected_result
    end
  end

  def test_index_without_statements
    get :index, :table => 'users'
    items = assigns[:items]
    assert_equal 4, items.length
  end

  def test_search_found
    get :index, :table => 'users', :search => 'Michel'
    assert_equal ['Michel'], assigns[:items].map(&:pseudo)
  end

  def test_search_not_found
    FixtureFactory.new :user, :pseudo => 'Johnny'
    get :index, :table => 'users', :search => 'Halliday'
    assert_equal 0, assigns[:items].length
  end

  private
  def assert_asearch name, pseudos
    get :index, :table => 'users', :asearch => name, :order => 'pseudo'
    assert_equal pseudos, assigns[:items].map(&:pseudo), assigns[:items]
  end

  def add_filter_to_test name, result, description
    @settings.filters[name] = description
    @expectations[name] = result
  end

end