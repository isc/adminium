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
  
  test "sorted index by pseudo desc" do
    FixtureFactory.new(:user, pseudo: 'Alberto' )
    FixtureFactory.new(:user, pseudo: 'Zoé' )
    visit resources_path(:users)
    find('a[title="sort by Pseudo A &rarr; Z"]').click
    assert_equal 'Zoé', find(".items-list tr:nth-child(2) td[data-column-name=pseudo]").text
    find('a[title="sort by Pseudo Z &rarr; A"]').click
    assert_equal 'Alberto', find(".items-list tr:nth-child(2) td[data-column-name=pseudo]").text
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
    assert_equal "", find('dd[data-column-name=start_date]').text
  end

  test "custom column has_many" do
    user = FixtureFactory.new(:user).factory
    2.times { FixtureFactory.new :comment, user_from_test: user }
    Resource::Base.any_instance.stubs(:columns).returns listing: ['has_many/comments'], serialized: [], search: []
    visit resources_path(:users)
    assert page.has_css?('td.hasmany a', text: '2')
  end

  test "custom column belongs_to" do
    FixtureFactory.new(:comment, user_from_test: FixtureFactory.new(:user, pseudo: 'bob').factory)
    Resource::Base.any_instance.stubs(:columns).returns listing: ['user.pseudo'], serialized: [], search: []
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

end
