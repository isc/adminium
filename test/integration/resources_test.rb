require 'test_helper'

class ResourcesTest < ActionDispatch::IntegrationTest
  
  test "index on resources for users table" do
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
  
end
