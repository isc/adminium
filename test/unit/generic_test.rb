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
    assert_equal(nil, @generic.foreign_keys[:users])
  end
  
  test "associations" do
    assert_equal({foreign_key: :user_profile_id, table: :user_profiles, primary_key: :id},
      @generic.associations[:users][:belongs_to][:user_profile])
    assert_equal({foreign_key: :user_profile_id, table: :user_profiles, primary_key: :id},
      @generic.associations[:user_profiles][:has_many][:users])
  end
  
  def expected_tables
    [:comments,  :documents,  :groups,  :posts,  :roles,  :roles_users,  :schema_migrations,  :user_profiles,  :users]
  end

end