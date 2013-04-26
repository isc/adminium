require 'test_helper'

class ColumnSettingsTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
    login
  end
  
  test "column settings for foreign key column" do
    group = FixtureFactory.new(:group, name: 'Admins').factory
    FixtureFactory.new(:user, group_id: group.id)
    visit column_setting_path(:users, column: 'group_id')
    select 'name', from: 'Label column'
    click_button 'Save settings'
    visit resources_path(:users)
    assert_equal resource_path(:groups, group), page.find('td.foreignkey a')['href']
    assert_equal 'Admins', page.find('td.foreignkey a').text
  end
  
  test "change visibility from column settings" do
    FixtureFactory.new :user
    visit column_setting_path(:users, column: 'pseudo')
    check 'Hidden column'
    click_button 'Save settings'
    visit resources_path(:users)
    assert !page.has_css?('th.column_header[data-column-name="pseudo"]')
  end
  
end
