class AddDecryptedDbUrlToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :decrypted_db_url, :string
    Account.where('encrypted_db_url IS NOT NULL').find_each |account| do
      account.decrypted_db_url = account.db_url
      account.save!
    end
  end
end
