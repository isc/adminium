require 'test_helper'

class SearchesTest < ActionDispatch::IntegrationTest
  def setup
    @account = login
  end

  test 'search on jsonb column' do
    FixtureFactory.new(:role, metadata: { level: 12 })
    FixtureFactory.new(:role, metadata: { level: 23 })
    visit resources_path(:roles)
    assert_text '2 records'
    click_on 'All records'
    click_on 'New filter'
    select 'metadata'
    select 'contains'
    find('input[data-type="jsonb"]').set '{"level": 23'
    click_on 'Search'
    assert_text '{"level": 23 cannot be parsed as JSON'
    click_on 'All records'
    click_on 'New filter'
    select 'metadata'
    select 'contains'
    find('input[data-type="jsonb"]').set '{"level": 23}'
    click_on 'Search'
    assert_text '1 record'
    click_on 'last search'
    click_on 'Delete'
    click_on 'All records'
    assert_no_text 'last search'
  end
end
