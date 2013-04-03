require 'test_helper'

class ResourcesTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
  end
  
  test "index on resources for users table" do
    FixtureFactory.new(:user)
    login
    visit resources_path(:users)
    assert page.has_css?('table.items-list')
    assert page.has_css?('th a', :text => 'First name')
    uncheck 'First name'
    click_button 'Save settings'
    assert !page.has_css?('th a', :text => 'First name')
  end

  test "creating a comment (polymorphic belongs_to)" do
    login
    visit resources_path(:comments)
    link = find('a[title="Create a new row"]')
    link.click()
  end

  test "save and create another" do
    login
    visit new_resource_path(:users)
    # save_and_open_page
  end

  test "save the date" do
    login
    visit new_resource_path(:documents)
    click_button 'Save'
    assert "", find('dd[data-column-name=start_date]').text
  end

  test "custom column has_many" do
    user = FixtureFactory.new(:user).factory
    2.times { FixtureFactory.new :comment, user_from_test: user }
    login
    Settings::Base.any_instance.stubs(:columns).returns listing: ['has_many/comments'], serialized: [], search: []
    visit resources_path(:users)
    assert page.has_css?('td.hasmany a', :text => '2')
  end

  test "custom column belongs_to" do
    FixtureFactory.new(:comment, user_from_test: FixtureFactory.new(:user, pseudo: 'bob').factory)
    login
    Settings::Base.any_instance.stubs(:columns).returns listing: ['user.pseudo'], serialized: [], search: []
    visit resources_path(:comments)
    assert page.has_css?('td', :text => 'bob')
  end

end
