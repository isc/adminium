class RemoveMoreColumnsFromAccounts < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :plan
    remove_column :accounts, :callback_url
    remove_column :accounts, :heroku_id
    remove_column :accounts, :tables_count
    remove_column :accounts, :source
  end
end
