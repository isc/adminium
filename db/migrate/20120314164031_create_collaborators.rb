class CreateCollaborators < ActiveRecord::Migration
  def change
    create_table :collaborators do |t|
      t.references :user
      t.references :account
      t.string :email, :null => false
      t.timestamps
    end
    add_index :collaborators, :user_id
    add_index :collaborators, :account_id
  end
end
