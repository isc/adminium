class AddKindToCollaborators < ActiveRecord::Migration
  def change
    add_column :collaborators, :kind, :string
    Collaborator.update_all "kind = 'google'"
  end
end
