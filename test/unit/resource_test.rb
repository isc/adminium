require 'test_helper'

class GenericTest < ActiveSupport::TestCase

  def setup
    account = Factory :account
    @generic = Generic.new account
  end
  
  def teardown
    @generic.cleanup
  end

  test "composite primary keys by convention" do
    resource = Resource::Base.new @generic, :roles_users
    assert_equal [:role_id, :user_id], resource.primary_keys
  end
  
  test "sanitize label_colum when loading" do
    resource = Resource::Base.new @generic, :users
    resource.label_column = 'deprecated_column'
    resource.save
    resource = Resource::Base.new @generic, :users
    assert_nil resource.label_column
    resource.label_column = 'pseudo'
    resource.save
    resource = Resource::Base.new @generic, :users
    assert_equal 'pseudo', resource.label_column
  end
  
  test "pg_array extension" do
    resource = Resource::Base.new @generic, :users
    assert_equal :string_array, resource.column_info(:nicknames)[:type]
  end

end