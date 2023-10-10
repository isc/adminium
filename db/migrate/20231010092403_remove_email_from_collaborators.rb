class RemoveEmailFromCollaborators < ActiveRecord::Migration[5.2]
  def change
    remove_column :collaborators, :email
  end
end
