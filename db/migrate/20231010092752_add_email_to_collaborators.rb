class AddEmailToCollaborators < ActiveRecord::Migration[5.2]
  def change
    add_column :collaborators, :email, :string
  end
end
