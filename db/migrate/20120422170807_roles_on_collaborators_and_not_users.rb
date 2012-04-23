class RolesOnCollaboratorsAndNotUsers < ActiveRecord::Migration
  def up
    rename_table :roles_users, :collaborators_roles
    rename_column :collaborators_roles, :user_id, :collaborator_id
  end

  def down
    rename_table :roles_collaborators, :roles_users
    rename_column :roles_users, :collaborator_id, :user_id
  end
end