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
    assert_equal(expected_tables.size - 5, table_sizes.size)
    assert_equal [3], table_sizes.values.map(&:length).uniq
  end

  test 'foreign keys' do
    assert_nil @generic.foreign_keys[:users]
  end

  test 'associations' do
    assert @generic.associations.include?(foreign_key: :user_profile_id, referenced_table: :user_profiles,
      primary_key: :id, table: :users)
  end

  test 'polymorphic associations' do
    assert @generic.associations.include?(foreign_key: :commentable_id, referenced_table: nil, primary_key: :id,
      table: :comments, polymorphic: true)
  end

  def expected_tables
    %i(comments documents groups posts roles roles_users schema_migrations uploaded_files user_profiles users
       pg_stat_activity pg_stat_all_indexes pg_stat_user_tables pg_statio_user_tables pg_statio_user_indexes)
  end
end
