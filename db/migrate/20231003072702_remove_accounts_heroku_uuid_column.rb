class RemoveAccountsHerokuUuidColumn < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :heroku_uuid
  end
end
