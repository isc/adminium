class RemoveApiKeyFromAccounts < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :api_key
  end
end
