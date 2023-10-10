class RemoveDeletedAtFromAccounts < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :deleted_at
  end
end
