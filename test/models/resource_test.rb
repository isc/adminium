require 'test_helper'

class ResourceTest < ActiveSupport::TestCase
  def setup
    account = create :account
    @generic = Generic.new account
  end

  def teardown
    @generic.cleanup
  end

  test 'composite primary keys by convention' do
    resource = Resource.new @generic, :roles_users
    assert_equal %i[role_id user_id], resource.primary_keys
  end

  test 'sanitize label_colum when loading' do
    resource = Resource.new @generic, :users
    resource.table_configuration.update! label_column: 'deprecated_column'
    resource = Resource.new @generic, :users
    assert_nil resource.label_column
    resource.table_configuration.update! label_column: 'pseudo'
    resource = Resource.new @generic, :users
    assert_equal 'pseudo', resource.label_column
  end

  test 'pg_array extension' do
    resource = Resource.new @generic, :users
    assert_equal :varchar_array, resource.column_info(:nicknames)[:type]
  end
end
