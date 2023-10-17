class RemoveDbUrlSetupMethodFromAccounts < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :db_url_setup_method
  end
end
