class RemoveColumnDecryptedDbUrlOnAccounts < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :decrypted_db_url
  end
end
