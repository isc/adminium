class RemoveOwnerEmailFromAccounts < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :owner_email
  end
end
