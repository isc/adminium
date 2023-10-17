require 'test_helper'

class SchemasTest < ActionDispatch::IntegrationTest
  def setup
    @account = login
  end

  test 'schema page' do
    visit schema_path(:users)
    assert_text 'Column name'
    assert_selector 'a', text: 'Add a column'
    save_screenshot 'schema_page'
  end

  test 'readonly schema page' do
    role = create :role
    collaborator = create :collaborator, account: @account, is_administrator: false, roles: [role]
    page.set_rack_session user_id: collaborator.user_id, collaborator_id: collaborator.id
    visit schema_path(:users)
    assert_text "You haven't the permission to perform show on users"
    role.update permissions: {'users' => {'read' => '1'}}
    visit schema_path(:users)
    assert_no_text "You haven't the permission to perform show on users"
    assert_text 'Column name'
    assert_no_selector 'a', text: 'Add a column'
  end

  test 'create a table' do
    visit new_schema_path
    save_screenshot 'schema_create_table'
  end
end
