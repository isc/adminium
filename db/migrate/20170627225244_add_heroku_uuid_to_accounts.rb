class AddHerokuUuidToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :heroku_uuid, :string
  end
end
