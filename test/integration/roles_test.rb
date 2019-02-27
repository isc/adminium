require 'test_helper'

class RolesTest < ActionDispatch::IntegrationTest
  test 'role creation and edition' do
    login create(:account, plan: Account::Plan::ENTERPRISE)
    visit dashboard_path
    click_on 'Close' # Tips modal
    click_on 'Signed in as'
    click_link 'Roles and permissions'
    click_link 'Create your first role'
    fill_in 'Name', with: 'Users read only'
    check 'role[permissions][users][create]'
    save_screenshot 'role_creation.png'
    click_button 'Create Role'
    assert_text 'Role successfully created'
    save_screenshot 'roles_and_permissions.png'
    click_link 'Users read only'
    assert find('input[name="role[permissions][users][create]"]').checked?
    click_on 'Add a collaborator'
    fill_in 'Email', with: 'john@mail.com'
    check 'Users read only'
    save_screenshot 'account_collaborators.png'
    click_on 'Add a collaborator'
    assert_text 'Collaborator added'
    click_link_with_title 'Edit this collaborator roles'
    within('.modal') { fill_in 'Email', with: 'john@mail.net' }
    click_on 'Update Collaborator'
    assert_text 'Changes on john@mail.net saved'
    assert_no_text 'john@mail.com'
  end
end
