require 'test_helper'

class SchemasTest < ActionDispatch::IntegrationTest
  
  def setup
    login
  end

  test "schema page" do
    visit schema_path(:users)
  end
  
  test "create a table" do
    visit new_schema_path
  end
  
end