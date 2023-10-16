class AddTokenToCollaborators < ActiveRecord::Migration[5.2]
  def change
    add_column :collaborators, :token, :string, null: false
  end
end
