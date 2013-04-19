require 'test_helper'

class ResourcesControllerTest < ActionController::TestCase

  def setup
    @account = Factory :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    @fixtures = []
    ['Michel', 'Martin', nil].each_with_index do |pseudo, index|
     user = FixtureFactory.new :user, :pseudo => pseudo, :admin => false, :age => (17 + index), :activated_at => (2 * (index - 1)).week.ago
     @fixtures.push user
    end
    user = FixtureFactory.new :user, :pseudo => 'Loulou', :last_name => '', :admin => true, :age => 18, :activated_at => 5.minutes.ago
    @fixtures.push user
  end

  def teardown
    assert_response :success
  end

  def test_advanced_search_operators
    generic = Generic.new @account
    @resource = Resource::Base.new(generic, :users)
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

    add_filter_to_test 'date_before', [nil], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"before", "operand" => 1.hour.ago.strftime('%m/%d/%Y')}]
    add_filter_to_test 'date_after', ['Michel'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"after", "operand" => 1.hour.ago.strftime('%m/%d/%Y')}]

    add_filter_to_test 'date_today', ['Loulou', 'Martin'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"today", "operand" => ""}]
    add_filter_to_test 'date_yesterday', [], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"yesterday", "operand" => ""}]
    add_filter_to_test 'date_on', ['Loulou','Martin'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"on", "operand" => 1.hour.ago.strftime('%m/%d/%Y')}]
    
    add_filter_to_test 'date_this_week', ['Loulou', 'Martin'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"this_week", "operand" => ""}]
    add_filter_to_test 'date_last_week', [], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"last_week", "operand" => ""}]

    add_filter_to_test 'string_blank', ["Loulou", "Martin", "Michel", nil], [{"column" => 'last_name', "type" => "string", "operator"=>"blank"}]
    add_filter_to_test 'string_present', [], [{"column" => 'last_name', "type" => "string", "operator"=>"present"}]

    add_filter_to_test 'and_grouping', ['Loulou'], [{"column" => 'pseudo', "type" => "string", "operator"=>"not_null"}, {"column" => 'admin', "type" => "boolean", "operator"=>"is_true"}]
    add_filter_to_test 'or_grouping', ['Loulou', 'Michel'], [{"column" => 'age', "type" => "integer", "operator"=>"=", 'operand' => 17}, {"column" => 'admin', "type" => "boolean", "operator"=>"is_true", 'grouping' => 'or'}]

    @resource.save

    @expectations.each do |filter_name, expected_result|
      assert_asearch filter_name, expected_result
    end
  end

  def test_index_without_statements
    get :index, :table => 'users'
    items = assigns[:items]
    assert_equal 4, items.count
  end

  def test_json_response
    get :index, :table => 'users', :order=> 'pseudo', :format => 'json'
    data = JSON.parse(@response.body)
    assert_equal ["Loulou", "Martin", "Michel", nil], assigns[:items].map{|i|i[:pseudo]}
    assert_equal 4, data['total_count']
  end

  def test_csv_response
    get :index, :table => 'users', :order=> 'pseudo', :format => 'csv'
    lines = @response.body.split("\n")
    assert_equal 5, lines.length
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

  def test_bulk_edit
    @records = @fixtures.map &:save!
    get :bulk_edit, :table => 'users', :record_ids => @records.map(&:id)
    assert_equal @records.map(&:id), assigns[:record_ids].map(&:to_i)
  end

  def test_search_for_association_input
    get :search, :table => 'users', :search => 'Loulou'
    data = JSON.parse(@response.body)
    assert_equal 1, data.length
    assert_equal "Loulou", data.first['pseudo']
  end

  def test_statistics
    settings = Generic.new(@account).table('users').settings
    enum_integer = {"column_name"=>"kind", "values"=>{"1"=>{"color"=>"bleu", "label"=>"Kind1"}, "2"=>{"color"=>"red", "label"=>"Kind2"}}}
    enum_string = {"column_name"=>"role", "values"=>{"1"=>{"color"=>"black", "label"=>"Role1"}, "2"=>{"color"=>"white", "label"=>"Role2"}}}
    settings.enum_values = [enum_integer, enum_string]
    settings.save
    @records = @fixtures.map &:save!
    get :index, :table => 'users'
    assert_equal({
      "age"=>{"max"=>19, "min"=>17, "avg"=>18.0},
      "role"=>{{"color"=>"black", "label"=>"Role1"}=>0, {"color"=>"white", "label"=>"Role2"}=>0},
      "kind"=>{{"color"=>"bleu", "label"=>"Kind1"}=>0, {"color"=>"red", "label"=>"Kind2"}=>0},
      "admin"=>{"true"=>1, "false"=>3, "null"=>0}
      }, assigns(:statistics))
  end
  
  def test_import
    user = FixtureFactory.new(:user, :pseudo => 'Johnny').factory
    datas = {
      create: [["juan", "Juan", "De La Motte", "1", "28", "2012-04-01 00:00:00 UTC", false, "DRH", "2", nil, "2013-03-13", nil, "2013-04-19 15:39:52 UTC", "2013-04-19 15:39:52 UTC"]],
      update: [[user.id.to_s, "martine", "Martine", "De La Motte", "1", "28", "2013-04-01 00:00:00 UTC", true, "PDG", "2", nil, "2013-03-13", nil, "2013-04-19 15:39:52 UTC", "2013-04-19 15:39:52 UTC"]],
      headers: ["id", "pseudo", "first_name", "last_name", "group_id", "age", "activated_at", "admin", "role", "kind", "user_profile_id", "birthdate", "file", "created_at", "updated_at"]
    }.to_json
    post :perform_import, table: :users, data: datas
    assert_response :success
  end

  private
  def assert_asearch name, pseudos
    get :index, :table => 'users', :asearch => name, :order => 'pseudo'
    assert_equal pseudos, assigns[:items].map{|r| r[:pseudo]}, assigns[:items]
  end

  def add_filter_to_test name, result, description
    @resource.filters[name] = description
    @expectations[name] = result
  end

end