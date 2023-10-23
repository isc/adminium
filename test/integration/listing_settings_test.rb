require 'test_helper'

class ListingsSettingsTest < ActionDispatch::IntegrationTest
  def setup
    login
  end

  test 'default order setting' do
    %w(b a c).each { |title| FixtureFactory.new(:comment, title: title) }
    visit resources_path(:comments)
    assert_equal %w(c a b), all('td[data-column-name=title]').map(&:text)
    click_link_with_title 'Listing settings'
    click_on 'Miscellaneous'
    select 'title', from: 'Default order'
    click_on 'Save settings'
    assert_text 'Settings successfully saved'
    assert_equal %w(c b a), all('td[data-column-name=title]').map(&:text)
    click_link_with_title 'Listing settings'
    click_on 'Miscellaneous'
    assert has_select?('Default order', selected: 'title')
    choose 'asc'
    click_on 'Save settings'
    assert_text 'Settings successfully saved'
    assert_equal %w(a b c), all('td[data-column-name=title]').map(&:text)
  end

  test 'per page setting' do
    26.times { |title| FixtureFactory.new(:comment) }
    visit resources_path(:comments)
    assert_equal 25, all('td[data-column-name=title]').size
    assert_text '1 - 25 of 26'
    click_link_with_title 'Listing settings'
    click_on 'Miscellaneous'
    fill_in 'Items per page', with: 50
    click_on 'Save settings'
    assert_text 'Settings successfully saved'
    assert_equal 26, all('td[data-column-name=title]').size
    assert_text '26 records'
  end

  test 'per page setting from the subheader' do
    26.times { |title| FixtureFactory.new(:comment) }
    visit resources_path(:comments)
    assert_equal 25, all('td[data-column-name=title]').size
    click_on 'of 26'
    click_on '50'
    assert_equal 26, all('td[data-column-name=title]').size
    assert_text '26 records'
  end
end
