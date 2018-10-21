require 'test_helper'

class RolesTest < ActionDispatch::IntegrationTest
  def setup
    login create(:account, plan: Account::Plan::ENTERPRISE)
  end

  test 'role creation and edition' do
    visit edit_account_path
    click_link 'Roles and permissions'
    click_link 'Create your first role'
    fill_in 'Name', with: 'Users read only'
    check 'role[permissions][users][create]'
    click_button 'Create Role'
    assert_text 'Role successfully created'
    click_link 'Users read only'
    assert find('input[name="role[permissions][users][create]"]').checked?
  end
end
