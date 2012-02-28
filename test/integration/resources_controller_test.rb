require 'test_helper'

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "index on resources for users table" do
    ::FIXED_ACCOUNT = Factory(:account).id
    get resources_path(:users)
  end
  
end
