class AddIsAdministratorToCollaborators < ActiveRecord::Migration
  def change
    add_column :collaborators, :is_administrator, :boolean, default: false, null: false

  end
end
