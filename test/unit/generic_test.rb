require 'test_helper'

class GenericTest < ActiveSupport::TestCase

  def setup
    account = Factory :account
    @generic = Generic.new account
  end

  test "get tables" do
    assert_equal expected_tables, @generic.tables
  end

  test "db_size" do
    assert_kind_of Integer, @generic.db_size
  end
  
  test "table_sizes" do
    table_sizes = @generic.table_sizes expected_tables
    assert_equal expected_tables.size, table_sizes.size
  end
  
  test "foreign keys" do
    @generic.foreign_keys
  end
  
  def expected_tables
    [:comments,  :documents,  :groups,  :posts,  :roles,  :roles_users,  :schema_migrations,  :user_profiles,  :users]
  end

end