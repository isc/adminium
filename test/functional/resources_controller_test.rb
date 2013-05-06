require 'test_helper'

class ResourcesControllerTest < ActionController::TestCase

  def setup
    @account = Factory :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    @fixtures = []
    ['Michel', 'Martin', nil].each_with_index do |pseudo, index|
     user = FixtureFactory.new :user, pseudo: pseudo, admin: false, age: (17 + index),
      activated_at: (2 * (index - 1)).week.ago
     @fixtures.push user
    end
    group = FixtureFactory.new(:group, name: 'Admins').factory
    user = FixtureFactory.new :user, pseudo: 'Loulou', last_name: '', admin: true, age: 18,
      activated_at: 5.minutes.ago, group_id: group.id
    @fixtures.push user
    @generic = Generic.new @account
  end

  def teardown
    assert_response(@expected_response_code || :success)
    @generic.cleanup
  end

  def test_advanced_search_operators
    @resource = Resource::Base.new @generic, :users
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

    #add_filter_to_test 'date_before', [nil], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"before", "operand" => Date.today.strftime('%m/%d/%Y')}]
    add_filter_to_test 'date_after', ['Michel'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"after", "operand" => Date.today.strftime('%m/%d/%Y')}]
    # FIXME time dependent, timezone stuff ; fails between midnight and two in CEST
    add_filter_to_test 'date_today', ['Loulou', 'Martin'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"today", "operand" => ""}]
    add_filter_to_test 'date_yesterday', [], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"yesterday", "operand" => ""}]
    add_filter_to_test 'date_on', ['Loulou','Martin'], [{"column" => 'activated_at', "type" => "datetime", "operator"=>"on", "operand" => Date.today.strftime('%m/%d/%Y')}]
    
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
    @account.update_attribute :tables_count, 37
    get :index, table: 'users'
    items = assigns[:items]
    assert_equal 4, items.count
    assert_equal 9, @account.reload.tables_count
  end

  def test_json_response
    get :index, table: 'users', order: 'pseudo', format: 'json'
    data = JSON.parse(@response.body)
    assert_equal ["Loulou", "Martin", "Michel", nil], assigns[:items].map{|i|i[:pseudo]}
    assert_equal 4, data['total_count']
  end

  def test_csv_response
    get :index, table: 'users', order: 'pseudo', format: 'csv'
    lines = @response.body.split("\n")
    assert_equal 5, lines.length
  end
  
  def test_csv_response_with_belongs_to_column
    Resource::Base.any_instance.stubs(:columns).returns(export: [:'groups.name'])
    get :index, table: 'users', format: 'csv', order: 'id'
    lines = @response.body.split("\n")
    assert_equal 'Admins', lines[-1]
  end
  
  def test_csv_response_with_has_many_count
    FixtureFactory.new(:group)
    Resource::Base.any_instance.stubs(:columns).returns(export: [:'has_many/users'])
    get :index, table: 'groups', format: 'csv', order: 'id'
    lines = @response.body.split("\n")
    assert_equal '1', lines[-2]
    assert_equal '0', lines[-1]
  end

  def test_search_found
    get :index, table: 'users', search: 'Michel'
    assert_equal ['Michel'], assigns[:items].map{|i|i[:pseudo]}
  end

  def test_search_not_found
    FixtureFactory.new :user, pseudo: 'Johnny'
    get :index, table: 'users', search: 'Halliday'
    assert_equal 0, assigns[:items].count
  end

  def test_bulk_edit
    @records = @fixtures.map &:save!
    get :bulk_edit, table: 'users', record_ids: @records.map(&:id)
    assert_equal @records.map(&:id), assigns[:record_ids].map(&:to_i)
  end

  def test_search_for_association_input
    get :search, table: 'users', search: 'Loulou'
    data = JSON.parse @response.body
    assert_equal 1, data.length
    assert_equal "Loulou", data.first['pseudo']
  end

  def test_statistics
    settings = Resource::Base.new @generic, :users
    enum_integer = {"column_name"=>"kind", "values"=>{"1"=>{"color"=>"bleu", "label"=>"Kind1"}, "2"=>{"color"=>"red", "label"=>"Kind2"}}}
    enum_string = {"column_name"=>"role", "values"=>{"1"=>{"color"=>"black", "label"=>"Role1"}, "2"=>{"color"=>"white", "label"=>"Role2"}}}
    settings.enum_values = [enum_integer, enum_string]
    settings.columns[:listing] = [:id, :pseudo, :first_name, :last_name, :age, :activated_at, :admin, :role, :kind]
    settings.save
    @records = @fixtures.map &:save!
    get :index, table: 'users'
    assert_equal({
      "age"=>{"max"=>19, "min"=>17, "avg"=>18.0},
      "role"=>{{"color"=>"black", "label"=>"Role1"}=>0, {"color"=>"white", "label"=>"Role2"}=>0},
      "kind"=>{{"color"=>"bleu", "label"=>"Kind1"}=>0, {"color"=>"red", "label"=>"Kind2"}=>0},
      "admin"=>{"true"=>1, "false"=>3, "null"=>0}
      }, assigns(:statistics))
  end
  
  def test_import
    user = FixtureFactory.new(:user, pseudo: 'Johnny').factory
    datas = {
      create: [["juan", "Juan", "De La Motte", "1", "28", "2012-04-01 00:00:00 UTC", false, "DRH", "2", nil, "2013-03-13", nil, "2013-04-19 15:39:52 UTC", "2013-04-19 15:39:52 UTC"]],
      update: [[user.id.to_s, "martine", "Martine", "De La Motte", "1", "28", "2013-04-01 00:00:00 UTC", true, "PDG", "2", nil, "2013-03-13", nil, "2013-04-19 15:39:52 UTC", "2013-04-19 15:39:52 UTC"]],
      headers: ["id", "pseudo", "first_name", "last_name", "group_id", "age", "activated_at", "admin", "role", "kind", "user_profile_id", "birthdate", "file", "created_at", "updated_at"]
    }.to_json
    post :perform_import, table: :users, data: datas

    assert_equal({'success' => true}, JSON.parse(@response.body))
    get :index, table: 'users', asearch: 'Last import'
    assert_equal 2, assigns[:items].count
    assert_equal 'martine', assigns[:items].detect{|r| r[:id] == user.id}[:pseudo]
  end
  
  def test_order_desc
    get :index, table: :users, order: 'pseudo desc'
    assert_equal ["Michel", "Martin", "Loulou", nil], assigns[:items].map{|i| i[:pseudo]}
  end
  
  def test_order_asc
    get :index, table: :users, order: 'pseudo'
    assert_equal ["Loulou", "Martin", "Michel", nil], assigns[:items].map{|i| i[:pseudo]}
  end

  def test_check_existence
    user = FixtureFactory.new(:user).factory
    get :check_existence, table: 'users', id: [user.id], format: :json
    assert_equal({'success' => true, 'update' => true}, JSON.parse(@response.body))
    
    get :check_existence, table: 'users', id: [user.id.to_s], format: :json
    assert_equal({'success' => true, 'update' => true}, JSON.parse(@response.body))
    
    get :check_existence, table: 'users', id: [12321, user.id]
    assert_equal({'error' => true, 'ids' => ['12321']}, JSON.parse(@response.body))
    
    get :check_existence, table: 'users', id: [12321]
    assert_equal({'success' => true, 'update' => false}, JSON.parse(@response.body))
  end
  
  def test_bulk_destroy
    request.env["HTTP_REFERER"] = 'plop'
    post :bulk_destroy, table: :users, item_ids: [@fixtures[0].factory.id, @fixtures[1].factory.id]
    assert_raise(ActiveRecord::RecordNotFound) { @fixtures[0].reload! }
    assert_raise(ActiveRecord::RecordNotFound) { @fixtures[1].reload! }
    assert_nothing_raised { @fixtures[2].reload! }
    @expected_response_code = :redirect
  end

  def test_pet_project_limitation_for_xhr_request
    @account.update_attribute :plan, Account::Plan::PET_PROJECT
    xhr :get, :index, table: 'roles_users'
    assert_equal %w(widget id), JSON.parse(@response.body).keys
  end
  
  def test_no_unnecessary_eager_fetching
    FixtureFactory.new :user
    r = Resource::Base.new @generic, :users
    r.columns[:listing] = [:group_id]
    r.save
    get :index, table: 'users'
    # no label column on groups so we don't need to fetch the groups to generate links
    assert_equal({}, assigns(:associated_items))
  end

  private
  def assert_asearch name, pseudos
    get :index, table: 'users', asearch: name, order: 'pseudo'
    assert_equal pseudos, assigns[:items].map{|r| r[:pseudo]}, "#{name}: #{assigns[:items].inspect}"
  end

  def add_filter_to_test name, result, description
    @resource.filters[name] = description
    @expectations[name] = result
  end

end