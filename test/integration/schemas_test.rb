require 'test_helper'

class SchemasTest < ActionDispatch::IntegrationTest
  def setup
    @account = login
  end

  test 'schema page' do
    visit schema_path(:users)
    assert_text 'Table users'
  end

  test 'readonly schema page' do
    role = create :role
    collaborator = create :collaborator, account: @account, is_administrator: false, roles: [role]
    page.set_rack_session user: collaborator.user_id, collaborator: collaborator.id
    visit schema_path(:users)
    assert_text "You haven't the permission to perform show on users"
    role.update permissions: {'users' => {'read' => '1'}}
    visit schema_path(:users)
    assert_text 'Table users'
  end

  test 'create a table' do
    visit new_schema_path
  end
end
