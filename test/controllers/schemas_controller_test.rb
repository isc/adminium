require 'test_helper'

class SchemasControllerTest < ActionController::TestCase
  def setup
    @account = create_account_and_login
    @generic = Generic.new @account
  end

  def teardown
    @generic.db.drop_table(@table_name.to_sym) if @table_name
    @generic.cleanup
  end

  def test_not_admin_not_allowed
    collaborator = create :collaborator, is_administrator: false
    @generic.cleanup
    session[:user_id] = collaborator.user.id
    session[:collaborator_id] = collaborator.id
    @generic = Generic.new @account
    request.env['HTTP_REFERER'] = '/'
    get :new
    assert_response :redirect
    assert_equal 'You need administrator privileges to access this page.', flash[:error]
  end

  def test_admin_collaborators_allowed
    collaborator = create :collaborator, is_administrator: true
    @generic.cleanup
    session[:user_id] = collaborator.user.id
    session[:collaborator_id] = collaborator.id
    get :new
    assert_response :success
  end

  def test_create_table_with_every_column_types
    columns = []
    %i(integer string datetime text float decimal time date blob boolean).each do |ruby_type|
      columns.push name: "#{ruby_type}_column", type: ruby_type
    end
    create_table columns
    db_types = ['integer', 'character varying(255)', 'timestamp without time zone', 'text', 'double precision', 'numeric', 'time without time zone', 'date', 'bytea', 'boolean']
    assert_equal db_types, (@schema.map {|c| c.last[:db_type]})
  end

  def test_create_table_with_single_auto_i_pk
    create_table [{name: 'id', type: :integer, primary: 'on'}]
    assert_schema [[:id, {oid: 23, db_type: 'integer', default: nil, allow_null: false, primary_key: true, type: :integer, ruby_default: nil, auto_increment: true}]]
  end

  def test_create_table_with_multiple_pk_and_no_auto_i
    create_table [{name: 'author_id', type: :integer, primary: 'on'}, {name: 'book_id', type: :integer, primary: 'on'}]
    assert_schema [
      [:author_id, {oid: 23, db_type: 'integer', default: nil, allow_null: false, primary_key: true, type: :integer, ruby_default: nil, auto_increment: false}],
      [:book_id, {oid: 23, db_type: 'integer', default: nil, allow_null: false, primary_key: true, type: :integer, ruby_default: nil, auto_increment: false}]
    ]
  end

  def test_create_table_with_unique_index
    create_table [{name: 'postal_code', type: 'string', unique: 'on'}]
    assert_schema [[:postal_code, {oid: 1043, db_type: 'character varying(255)', default: nil, allow_null: false, primary_key: false, type: :string, ruby_default: nil}]]
    assert_equal({:"#{@table_name}_postal_code_key" => {columns: [:postal_code], unique: true, deferrable: false}}, assigns[:resource].indexes)
  end

  def test_create_table_with_default_values
    create_table [
      {name: 'city', type: 'string', default: 'Paris'},
      {name: 'address', type: 'string', default: 'NULL'},
      {name: 'country', type: 'string', default: ''},
      {name: 'geo', type: 'string', default: nil}
    ]
    defaults = @schema.map(&:last).map {|c| [c[:default], c[:ruby_default]]}
    assert_equal ["'Paris'::character varying", 'Paris'], defaults.shift
    assert_equal [[nil, nil]], defaults.uniq
  end

  def test_create_table_failed
    post :create, params: {table_name: 'roles', columns: [{name: 'id', type: 'integer'}]}
    assert_response :success
    assert_match 'relation "roles" already exists', JSON.parse(@response.body)['error']
  end

  def test_rename_table
    create_table_for_test
    new_name = "my_new_name_#{rand(1_000_000)}"
    put :update, params: {id: @table_name, table_name: new_name}
    assert_response :redirect
    @table_name = new_name
    get :show, params: {id: @table_name}
    assert_response :success
  end

  def test_rename_table_fail
    create_table_for_test
    put :update, params: {id: @table_name, table_name: @table_name}
    assert_response :redirect
  end

  def test_drop_column
    create_table_for_test
    put :update, params: {id: @table_name, remove_column: 'mais_lol'}
    assert_response :redirect

    assert_equal [:id], schema.map(&:first)
    put :update, params: {id: @table_name, remove_column: 'mais_lol'}
    assert_response :redirect
  end

  def test_rename_column
    create_table_for_test
    put :update, params: {id: @table_name, new_column_name: 'mais_pas_lol', column_name: 'mais_lol'}
    assert_response :redirect

    assert_equal %i(id mais_pas_lol), schema.map(&:first)
    put :update, params: {id: @table_name, new_column_name: 'mais_pas_lol', column_name: 'mais_lol'}
    assert_response :redirect
  end

  def test_change_column_type
    create_table_for_test
    assert_equal 'character varying(255)', schema.last.last[:db_type]
    put :update, params: {id: @table_name, new_column_type: 'text', column_name: 'mais_lol'}
    column_definition = schema.last
    assert_equal :mais_lol, column_definition.first
    assert_equal 'text', column_definition.last[:db_type]
    put :update, params: {id: @table_name, new_column_type: 'boolean', column_name: 'mais_lol'}
    assert_response :redirect
    assert_equal 'text', schema.last.last[:db_type]
  end

  def test_drop_table
    @generic.db.create_table(:table_test) { primary_key :id }
    post :destroy, params: {id: 'table_test'}
    assert_response :redirect
    assert @generic.db.tables.include?(:table_test)
    post :destroy, params: {id: 'table_test', table_name_confirmation: 'table_test'}
    assert_response :redirect
    assert !@generic.db.tables.include?(:table_test)
    post :destroy, params: {id: 'unknown_table', table_name_confirmation: 'unknown_table'}
    assert_response :redirect
    assert_match 'table "unknown_table" does not exist', flash[:error]
  end

  def test_truncate_table
    create_table_for_test
    assert_equal 1, @generic.db[@table_name].insert(mais_lol: 'o')
    assert_equal 1, @generic.db[@table_name].count
    put :update, params: {id: @table_name, truncate: true, table_name_confirmation: @table_name}
    assert_equal 0, @generic.db[@table_name].count
    assert_equal 2, @generic.db[@table_name].insert(mais_lol: 'o')
    put :update, params: {id: @table_name, truncate: true, table_name_confirmation: @table_name, restart: true}
    assert_equal 0, @generic.db[@table_name].count
    assert_equal 1, @generic.db[@table_name].insert(mais_lol: 'o')
  end

  def test_add_column
    create_table_for_test
    put :update, params: {id: @table_name, add_column: 'true', columns: [{name: 'body', type: 'string'}]}
    assert_response :redirect
    assert_equal :body, schema.last.first
    assert_equal 'character varying(255)', schema.last.last[:db_type]
    put :update, params: {id: @table_name, add_column: 'true', columns: [{name: 'body', type: 'string'}]}
    assert_match 'column "body" of relation "table_test" already exists', flash[:error]
  end

  private

  def create_table_for_test
    @table_name = :table_test
    @generic.db.create_table(@table_name) do
      primary_key :id
      String :mais_lol, size: 255
    end
  end

  def create_table columns
    @table_name = 'test_name'
    post :create, params: {table_name: @table_name, columns: columns}
    assert_response :success
    get :show, params: {id: @table_name}
    @schema = assigns[:resource].schema
  end

  def schema
    @generic.db.schema(@table_name, reload: true)
  end

  def assert_schema schema
    assert_equal schema, @schema
  end
end
