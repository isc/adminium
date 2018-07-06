require 'test_helper'

class ResourcesControllerTest < ActionController::TestCase
  def setup
    @account = create :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    @fixtures = ['Michel', 'Martin', nil].each_with_index.map do |pseudo, index|
      FixtureFactory.new(:user, pseudo: pseudo, admin: false, age: (17 + index),
                                activated_at: (2 * (index - 1)).week.ago)
    end
    group = FixtureFactory.new(:group, name: 'Admins').factory
    @fixtures << FixtureFactory.new(:user, pseudo: 'Loulou', last_name: '', admin: true, age: 18,
                                           activated_at: 5.minutes.ago, group_id: group.id)
    @generic = Generic.new @account
  end

  def teardown
    assert_response(@expected_response_code || :success)
    @generic.cleanup
  end

  def test_advanced_search_null_operators
    setup_resource
    assert_asearch 'null_pseudo', [nil], [{'column' => 'pseudo', 'type' => 'string', 'operator' => 'null'}]
    assert_asearch 'not_null_pseudo', %w(Loulou Martin Michel), [{'column' => 'pseudo', 'type' => 'string', 'operator' => 'not_null'}]
  end

  def test_advanced_search_boolean_operators
    setup_resource
    assert_asearch 'boolean_true', ['Loulou'], [{'column' => 'admin', 'type' => 'boolean', 'operator' => 'is_true'}]
    assert_asearch 'boolean_false', ['Martin', 'Michel', nil], [{'column' => 'admin', 'type' => 'boolean', 'operator' => 'is_false'}]
  end

  def test_advanced_search_integer_operators
    setup_resource
    assert_asearch 'integer_gt', [nil], [{'column' => 'age', 'type' => 'integer', 'operator' => '>', 'operand' => '18'}]
    assert_asearch 'integer_gte', ['Loulou', 'Martin', nil], [{'column' => 'age', 'type' => 'integer', 'operator' => '>=', 'operand' => '18'}]
    assert_asearch 'integer_lt', %w(Michel), [{'column' => 'age', 'type' => 'integer', 'operator' => '<', 'operand' => '18'}]
    assert_asearch 'integer_lte', %w(Loulou Martin Michel), [{'column' => 'age', 'type' => 'integer', 'operator' => '<=', 'operand' => '18'}]
    assert_asearch 'integer_eq', %w(Loulou Martin), [{'column' => 'age', 'type' => 'integer', 'operator' => '=', 'operand' => '18'}]
    assert_asearch 'integer_not_eq', ['Michel', nil], [{'column' => 'age', 'type' => 'integer', 'operator' => '!=', 'operand' => '18'}]
    assert_asearch 'integer_in', ['Michel', nil], [{'column' => 'age', 'type' => 'integer', 'operator' => 'IN', 'operand' => '17, 19'}]
  end

  def test_advanced_search_string_operators
    setup_resource
    assert_asearch 'string_like', %w(Michel), [{'column' => 'pseudo', 'type' => 'string', 'operator' => 'like', 'operand' => 'iche'}]
    assert_asearch 'string_starts_with', %w(Martin Michel), [{'column' => 'pseudo', 'type' => 'string', 'operator' => 'starts_with', 'operand' => 'M'}]
    assert_asearch 'string_ends_with', %w(Martin), [{'column' => 'pseudo', 'type' => 'string', 'operator' => 'ends_with', 'operand' => 'tin'}]
    assert_asearch 'string_not_like', %w(Loulou Martin), [{'column' => 'pseudo', 'type' => 'string', 'operator' => 'not_like', 'operand' => 'iche'}]
    assert_asearch 'string_blank', ['Loulou', 'Martin', 'Michel', nil], [{'column' => 'last_name', 'type' => 'string', 'operator' => 'blank'}]
    assert_asearch 'string_present', [], [{'column' => 'last_name', 'type' => 'string', 'operator' => 'present'}]
  end

  def test_advanced_search_date_operators
    setup_resource
    assert_asearch 'date_before', [nil], [{'column' => 'activated_at', 'type' => 'datetime', 'operator' => 'before', 'operand' => Date.current.to_s}]
    assert_asearch 'date_after', %w(Michel), [{'column' => 'activated_at', 'type' => 'datetime', 'operator' => 'after', 'operand' => Date.current.to_s}]
    assert_asearch 'date_today', %w(Loulou Martin), [{'column' => 'activated_at', 'type' => 'datetime', 'operator' => 'today', 'operand' => ''}]
    assert_asearch 'date_yesterday', [], [{'column' => 'activated_at', 'type' => 'datetime', 'operator' => 'yesterday', 'operand' => ''}]
    assert_asearch 'date_on', %w(Loulou Martin), [{'column' => 'activated_at', 'type' => 'datetime', 'operator' => 'on', 'operand' => Date.current.to_s}]
    assert_asearch 'date_this_week', %w(Loulou Martin), [{'column' => 'activated_at', 'type' => 'datetime', 'operator' => 'this_week', 'operand' => ''}]
    assert_asearch 'date_last_week', [], [{'column' => 'activated_at', 'type' => 'datetime', 'operator' => 'last_week', 'operand' => ''}]
  end

  def test_advanced_search_grouping
    setup_resource
    assert_asearch 'and_grouping', %w(Loulou), [{'column' => 'pseudo', 'type' => 'string', 'operator' => 'not_null'}, {'column' => 'admin', 'type' => 'boolean', 'operator' => 'is_true'}]
    assert_asearch 'or_grouping', %w(Loulou Michel), [{'column' => 'age', 'type' => 'integer', 'operator' => '=', 'operand' => 17}, {'column' => 'admin', 'type' => 'boolean', 'operator' => 'is_true', 'grouping' => 'or'}]
  end

  def test_advanced_search_on_column_from_assoc
    setup_resource
    assert_asearch 'with group like admin', %w(Loulou),
      [{'column' => 'name', 'assoc' => 'group_id', 'type' => 'string', 'operator' => 'like', 'operand' => 'admin'}]
  end

  def test_advanced_search_on_columns_from_two_assocs
    setup_resource :roles_users
    description =
      [
        {'column' => 'pseudo', 'assoc' => 'user_id', 'type' => 'string', 'operator' => 'like', 'operand' => 'john'},
        {'column' => 'name', 'assoc' => 'role_id', 'type' => 'string', 'operator' => 'like', 'operand' => 'admin'}
      ]
    assert_asearch 'admin johns', [], description, 'roles_users', 'role_id'
  end

  def test_index_without_statements
    @account.update tables_count: 37
    get :index, params: {table: 'users'}
    items = assigns[:items]
    assert_equal 4, items.count
    assert_equal 10, @account.reload.tables_count
  end

  def test_json_response
    get :index, params: {table: 'users', order: 'pseudo', format: 'json'}
    data = JSON.parse(@response.body)
    assert_equal ['Loulou', 'Martin', 'Michel', nil], (assigns[:items].map {|i| i[:pseudo]})
    assert_equal 4, data['total_count']
  end

  def test_csv_response
    get :index, params: {table: 'users', order: 'pseudo', format: 'csv'}
    lines = @response.body.split("\n")
    assert_equal 5, lines.length
  end

  def test_csv_response_skip_headers_and_time_column
    FixtureFactory.new :user, daily_alarm: '08:37'
    Resource::Base.any_instance.stubs(:columns).returns(export: [:daily_alarm])
    Resource::Base.any_instance.stubs(:export_skip_header).returns true
    get :index, params: {table: 'users', order: 'id', format: 'csv'}
    lines = @response.body.split "\n"
    assert_equal 5, lines.length
    assert_equal '08:37', lines.last
  end

  def test_csv_response_with_belongs_to_column
    Resource::Base.any_instance.stubs(:columns).returns(export: %i(group_id.name))
    get :index, params: {table: 'users', format: 'csv', order: 'id'}
    lines = @response.body.split("\n")
    assert_equal 'Admins', lines.last
  end

  def test_csv_response_with_has_many_count
    FixtureFactory.new(:group)
    Resource::Base.any_instance.stubs(:columns).returns(export: [:'has_many/users/group_id'])
    get :index, params: {table: 'groups', format: 'csv', order: 'id'}
    lines = @response.body.split("\n")
    assert_equal '1', lines[-2]
    assert_equal '0', lines[-1]
  end

  def test_search_found
    get :index, params: {table: 'users', search: 'Michel'}
    assert_equal ['Michel'], (assigns[:items].map {|i| i[:pseudo]})
  end

  def test_search_not_found
    FixtureFactory.new :user, pseudo: 'Johnny'
    get :index, params: {table: 'users', search: 'Halliday'}
    assert_equal 0, assigns[:items].count
  end

  def test_bulk_edit
    @records = @fixtures.map(&:save!)
    get :bulk_edit, params: {table: 'users', record_ids: @records.map(&:id)}
    assert_equal @records.map(&:id), assigns[:record_ids].map(&:to_i)
  end

  def test_bulk_update
    FixtureFactory.clear_db
    request.env['HTTP_REFERER'] = 'http://example.com'
    names = %w(John Jane)
    users = Array.new(2) do |i|
      FixtureFactory.new(:user, age: 34, role: 'Developer', last_name: 'Johnson', first_name: names[i]).factory
    end
    params = {table: 'users', record_ids: users.map(&:id)}
    params[:users] = {role: '', last_name: '', first_name: '', age: 55}
    params[:users_nullify_settings] = {role: 'null', last_name: 'empty_string', first_name: ''}
    post :bulk_update, params: params
    get :index, params: {table: 'users'}
    assigns[:items].each do |user|
      assert_nil user[:role]
      assert_equal '', user[:last_name]
      assert names.include?(user[:first_name])
    end
  end

  def test_search_for_association_input
    get :search, params: {table: 'users', search: 'Loulou', primary_key: 'id'}
    data = JSON.parse @response.body
    assert_equal 1, data['results'].length
    assert_equal 'Loulou', data['results'].first['pseudo']
    assert_equal 'id', data['primary_key']
  end

  def test_update
    FixtureFactory.clear_db
    user = FixtureFactory.new(:user, age: 34, role: 'Developer', last_name: 'Johnson').factory
    params = {table: 'users', id: user.id, users: {role: '', last_name: '', age: ''},
              users_nullify_settings: {role: 'null', last_name: 'empty_string'}}
    post :update, params: params
    get :show, params: {table: 'users', id: user.id}
    item = assigns[:item]
    assert_nil item[:role]
    assert_nil item[:age]
    assert_equal '', item[:last_name]
  end

  def test_import
    user = FixtureFactory.new(:user, pseudo: 'Johnny').factory
    datas = {
      create: [['juan', 'Juan', 'De La Motte', '1', '28', '2012-04-01 00:00:00 UTC', false, 'DRH', '2', nil, '2013-03-13', nil, '2013-04-19 15:39:52 UTC', '2013-04-19 15:39:52 UTC']],
      update: [[user.id.to_s, 'martine', 'Martine', 'De La Motte', '1', '28', '2013-04-01 00:00:00 UTC', true, 'PDG', '2', nil, '2013-03-13', nil, '2013-04-19 15:39:52 UTC', '2013-04-19 15:39:52 UTC']],
      headers: %w(id pseudo first_name last_name group_id age activated_at admin role kind user_profile_id birthdate file created_at updated_at)
    }.to_json
    post :perform_import, params: {table: :users, data: datas}
    assert_equal({'success' => true}, JSON.parse(@response.body))
    get :index, params: {table: 'users', asearch: 'Last import'}
    assert_equal 2, assigns[:items].count
    assert_equal 'martine', assigns[:items].detect {|r| r[:id] == user.id}[:pseudo]
  end

  def test_import_with_pks_and_magic_timestamp_filling
    # FIXME: import feature incorrectly reports an error when importing with specific PKs if one of the specified pk value is below the max pk value in the database.
    @account.update application_time_zone: 'Paris', database_time_zone: 'UTC'
    Timecop.freeze ActiveSupport::TimeZone.new('Paris').parse('6/6/2013 15:36') do
      pk = @fixtures.last.factory.id + 1
      datas = {create: [[pk, 'Jean', 'Marais']], update: [], headers: %w(id first_name last_name)}.to_json
      post :perform_import, params: {table: :users, data: datas}
      assert_equal({'success' => true}, JSON.parse(@response.body))
      get :index, params: {table: 'users', asearch: 'Last import'}
      assert_equal 1, assigns[:items].count
      assigned_item = assigns[:items].detect {|r| r[:id] == pk}
      assert_equal 'Marais', assigned_item[:last_name]
      assert_equal '2013-06-06T15:36:00+02:00', assigned_item[:created_at].to_s
    end
  end

  def test_order_desc
    get :index, params: {table: :users, order: 'pseudo desc'}
    assert_equal ['Michel', 'Martin', 'Loulou', nil], (assigns[:items].map {|i| i[:pseudo]})
  end

  def test_order_asc
    get :index, params: {table: :users, order: 'pseudo'}
    assert_equal ['Loulou', 'Martin', 'Michel', nil], (assigns[:items].map {|i| i[:pseudo]})
  end

  def test_check_existence
    user = FixtureFactory.new(:user).factory
    post :check_existence, params: {table: 'users', id: [user.id], format: :json}
    assert_equal({'success' => true, 'update' => true}, JSON.parse(@response.body))

    post :check_existence, params: {table: 'users', id: [user.id.to_s], format: :json}
    assert_equal({'success' => true, 'update' => true}, JSON.parse(@response.body))

    post :check_existence, params: {table: 'users', id: [12_321, user.id]}
    assert_equal({'error' => true, 'ids' => ['12321']}, JSON.parse(@response.body))

    post :check_existence, params: {table: 'users', id: [12_321]}
    assert_equal({'success' => true, 'update' => false}, JSON.parse(@response.body))
  end

  def test_bulk_destroy
    request.env['HTTP_REFERER'] = 'plop'
    post :bulk_destroy, params: {table: :users, item_ids: [@fixtures[0].factory.id, @fixtures[1].factory.id]}
    assert_raise(ActiveRecord::RecordNotFound) { @fixtures[0].reload! }
    assert_raise(ActiveRecord::RecordNotFound) { @fixtures[1].reload! }
    assert_nothing_raised { @fixtures[2].reload! }
    @expected_response_code = :redirect
  end

  def test_pet_project_limitation_for_xhr_request
    @account.update plan: Account::Plan::PET_PROJECT
    get :index, params: {table: 'roles_users'}, xhr: true
    assert_equal %w(widget id), JSON.parse(@response.body).keys
  end

  def test_no_unnecessary_eager_fetching
    FixtureFactory.new :user
    setup_resource
    @resource.columns[:listing] = [:group_id]
    @resource.save
    get :index, params: {table: 'users'}
    # no label column on groups so we don't need to fetch the groups to generate links
    assert_equal({}, assigns(:associated_items))
  end

  def test_xhr_update
    Timecop.freeze ActiveSupport::TimeZone.new('Paris').parse('2013-06-02 22:22:07') do
      @account.update database_time_zone: 'UTC', application_time_zone: 'Paris'
      user = FixtureFactory.new(:user)
      put :update, params: {users: {created_at: '2013-06-02 22:02:07'}, table: 'users',
                            id: user.factory.id.to_s, format: 'json'}
      result = JSON.parse(@response.body)
      assert result['value'][/data-raw-value="2013-06-02 22:02:07"/]
      user.reload!
      assert_equal '2013-06-02 20:22:07 UTC', user.factory.updated_at.to_s
    end
  end

  private

  def assert_asearch name, pseudos, description, table = 'users', order = 'pseudo'
    create :search, name: name, table: table, account: @account, conditions: description, generic: @generic
    get :index, params: {table: table, asearch: name, order: order}
    assert_equal pseudos, (assigns[:items].map {|r| r[:pseudo]}), "#{name}: #{assigns[:items].inspect}"
  end

  def setup_resource table = :users
    @resource = Resource::Base.new @generic, table
  end
end
