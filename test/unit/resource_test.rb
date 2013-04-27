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

end