require 'test_helper'

class ColumnSettingsTest < ActionDispatch::IntegrationTest
  def setup
    FixtureFactory.clear_db
    login
  end

  test 'column settings for foreign key column' do
    group = FixtureFactory.new(:group, name: 'Admins').factory
    FixtureFactory.new(:user, group_id: group.id)
    visit resources_path(:users)
    find('th[data-column-name="group_id"]').hover
    find('th .fa-cog').click
    open_accordion 'Association discovery', selector: 'label', text: 'Label column'
    select 'name', from: 'Label column'
    save_screenshot 'column_settings_modal.png'
    click_button 'Save settings'
    assert_no_selector '.modal'
    click_link 'Admins'
    assert_equal resource_path(:groups, group), current_path
  end

  test 'change visibility from column settings' do
    FixtureFactory.new :user
    visit column_setting_path(:users, column: 'pseudo', view: 'listing')
    check 'Hidden column'
    click_button 'Save settings'
    visit resources_path(:users)
    assert_no_selector 'th.column_header[data-column-name="pseudo"]'
  end

  test 'show on various types' do
    %w(id pseudo created_at admin file Average_Price_Online__c).each do |column|
      visit column_setting_path(:users, column: column, view: 'listing')
    end
  end
end
