class RemoveKindFromCollaborators < ActiveRecord::Migration[5.2]
  def change
    remove_column :collaborators, :kind
  end
end
