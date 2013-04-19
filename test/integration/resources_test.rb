# encoding: UTF-8
require 'test_helper'

class ResourcesTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
    login
  end
  
  test "index on resources for users table" do
    FixtureFactory.new(:user)
    visit resources_path(:users)
    assert page.has_css?('table.items-list')
    assert page.has_css?('th a', text: 'First name')
    uncheck 'First name'
    click_button 'Save settings'
    assert !page.has_css?('th a', text: 'First name')
  end
  
  test "sorted index by column asc and desc" do
    FixtureFactory.new(:user, pseudo: 'Alberto' )
    FixtureFactory.new(:user, pseudo: 'Zoé' )
    visit resources_path(:users)
    find('a[title="Sort by Pseudo A &rarr; Z"]').click
    assert_equal 'Zoé', find(".items-list tr:nth-child(2) td[data-column-name=pseudo]").text
    find('a[title="Sort by Pseudo Z &rarr; A"]').click
    assert_equal 'Alberto', find(".items-list tr:nth-child(2) td[data-column-name=pseudo]").text
  end
  
  test "search a string in columns" do
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Haliday', role: 'singer')
    FixtureFactory.new(:user, first_name: 'Mariah', last_name: 'Carey', role: 'singer')
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: "Deep", role: "actor")
    visit resources_path(:users)
    fill_in 'search_input', with: "Johnny"
    click_button 'search_btn'
    assert page.has_content? 'Haliday'
    assert page.has_content? 'Deep'
    assert page.has_no_content? 'Carey'
    
    fill_in 'search_input', with: "Johnny singer"
    click_button 'search_btn'
    assert page.has_content? 'Haliday'
    assert page.has_no_content? 'Deep'
    assert page.has_no_content? 'Carey'
  end
  
  test "search on integer columns" do
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Haliday', age: 61)
    FixtureFactory.new(:user, first_name: 'Mariah', last_name: 'Carey', age: 661)
    visit resources_path(:users)
    fill_in 'search_input', with: "61"
    click_button 'search_btn'
    assert page.has_content? 'Haliday'
    assert page.has_no_content? 'Carey'
  end

  test "creating a comment (polymorphic belongs_to)" do
    visit resources_path(:comments)
    link = find('a[title="Create a new row"]')
    link.click()
  end

  test "save new" do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    click_button 'Save'
    assert page.has_content?('successfully created')
    assert_equal 'Bobulus', find('td[data-column-name=pseudo]').text
  end
  
  test "failed save due to value out of range for db" do
    visit new_resource_path(:users)
    fill_in 'Age', with: '83829384728832'
    click_button 'Save'
    assert page.has_css?('.alert.alert-error')
    assert page.has_content?('New User')
    assert_equal '83829384728832', find('input[type=number][name="users[age]"]').value
  end

  test "save new and create another" do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    click_button 'Save and create another'
    assert page.has_content?("New User")
  end
  
  test "save new and continue editing" do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    click_button 'Save and continue editing'
    assert_equal 'Bobulus', find('input[type=text][name="users[pseudo]"]').value
  end

  test "save the date" do
    visit new_resource_path(:documents)
    click_button 'Save'
    assert_equal 'null', find('td[data-column-name=start_date]').text
  end

  test "custom column has_many" do
    user = FixtureFactory.new(:user).factory
    2.times { FixtureFactory.new :comment, user_from_test: user }
    Resource::Base.any_instance.stubs(:columns).returns listing: [:'has_many/comments'], serialized: [], search: []
    visit resources_path(:users)
    assert page.has_css?('td.hasmany a', text: '2')
  end

  test "custom column belongs_to" do
    FixtureFactory.new(:comment, user_from_test: FixtureFactory.new(:user, pseudo: 'bob').factory)
    Resource::Base.any_instance.stubs(:columns).returns listing: ['users.pseudo'], serialized: [], search: []
    visit resources_path(:comments)
    assert page.has_css?('td', text: 'bob')
  end
  
  test "destroy from show" do
    user = FixtureFactory.new(:user).factory
    visit resource_path(:users, user)
    destroy_url = find("a[data-method=delete]")['href']
    Capybara.current_session.driver.delete destroy_url
    visit Capybara.current_session.driver.response.location
    visit resource_path(:users, user)
    assert_equal resources_path(:users), page.current_path
    assert page.has_content?("does not exist")
  end
  
  test "clone from show" do
    user = FixtureFactory.new(:user, pseudo: "Cloned Boy", age: 5).factory
    visit resource_path(:users, user)
    find("a[title=Clone]").click()
    click_button "Save"
    assert_equal "Cloned Boy", find('td[data-column-name=pseudo]').text
    assert_equal "5", find('td[data-column-name=age]').text
    assert_equal user.id + 1, find('div[data-table=users]')['data-item-id'].to_i
  end
  
  test "update from edit" do
    user = FixtureFactory.new(:user, pseudo: 'Bob', age: 36).factory
    visit edit_resource_path(:users, user)
    assert_equal 'Bob', find('input[type=text][name="users[pseudo]"]').value
    assert_equal '36', find('input[type=number][name="users[age]"]').value
    fill_in 'Pseudo', with: 'Bobulus'
    fill_in 'Age', with: '37'
    click_button 'Save'
    assert_equal 'Bobulus', find('td[data-column-name=pseudo]').text
    assert_equal '37', find('td[data-column-name=age]').text
  end
  
  test "failed update" do
    user = FixtureFactory.new(:user).factory
    out_of_range_int = '3241234234141234'
    visit edit_resource_path(:users, user)
    fill_in 'Age', with: out_of_range_int
    click_button 'Save'
    assert page.has_css?('.alert.alert-error')
    assert page.has_content?("Editing User ##{user.id}")
    assert_equal out_of_range_int, find('input[type=number][name="users[age]"]').value
  end
  
  test "export rows" do
    FixtureFactory.new(:user, pseudo: "bobleponge")
    visit resources_path(:users)
    click_button 'Export 1 users to csv'
    assert page.has_content?('bobleponge')
  end
  
  test "show with belongs_to association" do
    group = FixtureFactory.new(:group).factory
    user = FixtureFactory.new(:user, group_id: group.id).factory
    visit resource_path(:users, user)
    click_link "Group ##{group.id}"
    assert_equal resource_path(:groups, group), page.current_path
  end
  
  test "show with belongs_to association with label_column set" do
    Resource::Base.any_instance.stubs(:label_column).returns 'name'
    group = FixtureFactory.new(:group, name: 'Admins').factory
    user = FixtureFactory.new(:user, group_id: group.id).factory
    visit resource_path(:users, user)
    click_link 'Admins'
    assert_equal resource_path(:groups, group), page.current_path
  end
  
  test "show with has_many association" do
    group = FixtureFactory.new(:group).factory
    3.times { FixtureFactory.new(:user, group_id: group.id) }
    visit resource_path(:groups, group)
    click_link 'Create a new associated User'
    assert_equal new_resource_path(:users), page.current_path
  end
  
end
