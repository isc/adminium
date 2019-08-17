require 'test_helper'

class ValidationsTest < ActionDispatch::IntegrationTest
  def setup
    @account = login
  end

  test 'validate uniqueness on update' do
    FixtureFactory.new(:user, first_name: 'Rob')
    user = FixtureFactory.new(:user, first_name: 'Bob').factory
    visit edit_resource_path(:users, user)
    click_link_with_title 'Form settings'
    click_link 'Validations'
    select 'Validates uniqueness of'
    select 'first_name'
    click_on 'Add'
    save_screenshot 'validations_configuration'
    click_on 'Save settings'
    assert_text 'Settings successfully saved'
    fill_in 'First name', with: 'Rob'
    click_on 'Save'
    assert_text 'Rob has already been taken.'
    save_screenshot 'validation_error'
    fill_in 'First name', with: 'Robert'
    click_on 'Save'
    assert_selector '.alert.alert-success'
    click_link_with_title 'Clone'
    fill_in 'First name', with: 'Rob'
    click_on 'Save'
    assert_text 'Rob has already been taken.'
    click_link_with_title 'Form settings'
    click_link 'Validations'
    assert_selector 'td', text: 'Validates uniqueness of'
    find('i.remove').click
    assert_no_selector 'td', text: 'Validates uniqueness of'
    click_on 'Save settings'
    assert_text 'Settings successfully saved'
    click_link_with_title 'Create a new row'
    fill_in 'First name', with: 'Rob'
    click_on 'Save'
    assert_text 'successfully created'
  end
end
