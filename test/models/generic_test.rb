require 'test_helper'

class GenericTest < ActiveSupport::TestCase
  def setup
    account = create :account
    @generic = Generic.new account
  end

  def teardown
    @generic.cleanup
  end

  test 'get tables' do
    assert_equal expected_tables, @generic.tables
  end

  test 'db_size' do
    assert_kind_of Integer, @generic.db_size
  end

  test 'table_sizes' do
    table_sizes = @generic.table_sizes expected_tables
    assert_equal expected_tables.size, table_sizes.size
    assert_equal :comments, table_sizes.first.first
    assert_equal 3, table_sizes.first.length
  end

  test 'foreign keys' do
    assert_equal(nil, @generic.foreign_keys[:users])
  end

  test 'associations' do
    assert_equal({foreign_key: :user_profile_id, referenced_table: :user_profiles, primary_key: :id, table: :users},
      @generic.associations[:users][:belongs_to][:user_profiles])
    assert_equal({foreign_key: :user_profile_id, referenced_table: :user_profiles, primary_key: :id, table: :users},
      @generic.associations[:user_profiles][:has_many][:users])
  end

  test 'polymorphic associations' do
    assert_equal({foreign_key: :commentable_id, referenced_table: nil, primary_key: :id, table: :comments, polymorphic: true},
    @generic.associations[:comments][:belongs_to][:commentables])
  end

  def expected_tables
    %i(comments documents groups posts roles roles_users schema_migrations uploaded_files user_profiles users pg_stat_activity pg_stat_all_indexes)
  end
end
