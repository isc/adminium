class AddDbUrlSetupMethodToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :db_url_setup_method, :string
    Account.where("encrypted_db_url is not null or plan = ?", 'deleted').update_all "db_url_setup_method = 'unknown'"
  end
end
